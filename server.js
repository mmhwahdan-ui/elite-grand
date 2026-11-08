const http = require('http');
const fs = require('fs');
const path = require('path');

const PORT = process.env.PORT || 8080;
const WEB_DIR = fs.existsSync(path.join(__dirname, 'public'))
  ? path.join(__dirname, 'public')
  : path.join(__dirname, 'build', 'web');
const DATA_FILE = path.join(__dirname, 'data.json');

const MIME_TYPES = {
  '.html': 'text/html; charset=utf-8',
  '.js': 'application/javascript',
  '.json': 'application/json',
  '.css': 'text/css',
  '.png': 'image/png',
  '.jpg': 'image/jpeg',
  '.svg': 'image/svg+xml',
  '.wasm': 'application/wasm',
  '.ttf': 'font/ttf',
  '.otf': 'font/otf',
};

// Smart Merge helper function: merges incoming list with server list by unique ID, skipping deleted items
function smartMerge(serverList, incomingList, deletedSet, dateField = 'updatedAt') {
  const map = new Map();

  // 1. Populate map with existing server items (if not deleted)
  for (const item of (serverList || [])) {
    if (item && item.id && (!deletedSet || !deletedSet.has(item.id))) {
      map.set(item.id, item);
    }
  }

  // 2. Merge incoming items (if not deleted)
  for (const item of (incomingList || [])) {
    if (!item || !item.id || (deletedSet && deletedSet.has(item.id))) continue;

    if (!map.has(item.id)) {
      // New item created on a phone -> insert it!
      map.set(item.id, item);
    } else {
      // Existing item -> keep the newer one based on timestamp
      const existing = map.get(item.id);
      const incomingTime = new Date(item[dateField] || item.createdAt || 0).getTime();
      const existingTime = new Date(existing[dateField] || existing.createdAt || 0).getTime();

      if (incomingTime >= existingTime) {
        map.set(item.id, { ...existing, ...item });
      }
    }
  }

  return Array.from(map.values());
}

const server = http.createServer((req, res) => {
  // CORS Headers
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'GET, POST, PUT, DELETE, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type, Accept, Authorization');

  if (req.method === 'OPTIONS') {
    res.writeHead(204);
    res.end();
    return;
  }

  const urlPath = req.url.split('?')[0];

  // --- Central Cloud Sync API Endpoint with Smart Merge & Tombstones ---
  if (urlPath === '/api/data' || urlPath === '/api/data/') {
    if (req.method === 'GET') {
      fs.readFile(DATA_FILE, 'utf8', (err, data) => {
        if (err) {
          res.writeHead(500, { 'Content-Type': 'application/json' });
          res.end(JSON.stringify({ error: 'Database read error' }));
          return;
        }
        try {
          const parsed = JSON.parse(data);
          const deletedSet = new Set(parsed.deletedIds || []);
          parsed.clients = (parsed.clients || []).filter(c => c && !deletedSet.has(c.id));
          parsed.payments = (parsed.payments || []).filter(p => p && !deletedSet.has(p.id) && !deletedSet.has(p.clientId));
          parsed.expenses = (parsed.expenses || []).filter(e => e && !deletedSet.has(e.id));
          parsed.serviceDays = (parsed.serviceDays || []).filter(d => d && !deletedSet.has(d.id) && !deletedSet.has(d.clientId));
          if (!parsed.openingBalances) {
            parsed.openingBalances = { bank: 0, wallet: 0, cash: 0 };
          }
          
          res.writeHead(200, { 'Content-Type': 'application/json; charset=utf-8' });
          res.end(JSON.stringify(parsed, null, 2));
        } catch (_) {
          res.writeHead(200, { 'Content-Type': 'application/json; charset=utf-8' });
          res.end(data);
        }
      });
      return;
    }

    if (req.method === 'PUT' || req.method === 'POST') {
      let body = '';
      req.on('data', (chunk) => {
        body += chunk;
      });
      req.on('end', () => {
        try {
          const incoming = JSON.parse(body);

          // Read current server data first to perform non-destructive merge
          fs.readFile(DATA_FILE, 'utf8', (readErr, currentRaw) => {
            let current = { clients: [], payments: [], expenses: [], serviceDays: [], users: [], deletedIds: [], openingBalances: { bank: 0, wallet: 0, cash: 0 } };
            if (!readErr && currentRaw) {
              try {
                current = JSON.parse(currentRaw);
              } catch (_) {}
            }

            // Union of deletedIds
            const allDeletedIds = Array.from(new Set([
              ...(Array.isArray(current.deletedIds) ? current.deletedIds : []),
              ...(Array.isArray(incoming.deletedIds) ? incoming.deletedIds : []),
            ]));
            const deletedSet = new Set(allDeletedIds);

            // Perform bidirectional smart merge, filtering out deleted items
            const mergedClients = smartMerge(current.clients, incoming.clients, deletedSet, 'updatedAt');
            const mergedPayments = smartMerge(current.payments, incoming.payments, deletedSet, 'createdAt');
            const mergedExpenses = smartMerge(current.expenses, incoming.expenses, deletedSet, 'createdAt');
            const mergedServiceDays = smartMerge(current.serviceDays, incoming.serviceDays, deletedSet, 'createdAt');
            const mergedUsers = smartMerge(current.users, incoming.users, new Set(), 'id');
            const mergedOpeningBalances = incoming.openingBalances || current.openingBalances || { bank: 0, wallet: 0, cash: 0 };

            const mergedData = {
              lastUpdated: new Date().toISOString(),
              deletedIds: allDeletedIds,
              openingBalances: mergedOpeningBalances,
              clients: mergedClients,
              payments: mergedPayments,
              expenses: mergedExpenses,
              serviceDays: mergedServiceDays,
              users: mergedUsers,
            };

            const jsonString = JSON.stringify(mergedData, null, 2);

            fs.writeFile(DATA_FILE, jsonString, 'utf8', (writeErr) => {
              if (writeErr) {
                res.writeHead(500, { 'Content-Type': 'application/json' });
                res.end(JSON.stringify({ error: 'Database write error' }));
                return;
              }
              res.writeHead(200, { 'Content-Type': 'application/json; charset=utf-8' });
              // Return the full merged state so caller updates immediately
              res.end(jsonString);
            });
          });
        } catch (parseErr) {
          res.writeHead(400, { 'Content-Type': 'application/json' });
          res.end(JSON.stringify({ error: 'Invalid JSON format' }));
        }
      });
      return;
    }
  }

  // --- Static Web Files Serving ---
  let reqPath = decodeURI(urlPath);
  if (reqPath === '/' || reqPath === '') {
    reqPath = '/index.html';
  }

  let filePath = path.join(WEB_DIR, reqPath);

  fs.stat(filePath, (err, stats) => {
    if (err || !stats.isFile()) {
      filePath = path.join(WEB_DIR, 'index.html');
    }

    const ext = path.extname(filePath).toLowerCase();
    const contentType = MIME_TYPES[ext] || 'application/octet-stream';

    fs.readFile(filePath, (readErr, content) => {
      if (readErr) {
        res.writeHead(500);
        res.end('Server Error');
        return;
      }
      res.writeHead(200, {
        'Content-Type': contentType,
      });
      res.end(content);
    });
  });
});

server.listen(PORT, () => {
  console.log(`Elite Grand Server & Smart Cloud Sync running at http://localhost:${PORT}`);
});
