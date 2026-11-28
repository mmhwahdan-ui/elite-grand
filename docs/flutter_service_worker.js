const CACHE_NAME = 'elite-grand-v8';

// Core assets to pre-cache on install for 100% offline standalone operation
const PRECACHE_ASSETS = [
  './',
  'index.html',
  'manifest.json',
  'favicon.png',
  'flutter.js',
  'flutter_bootstrap.js',
  'flutter_service_worker.js',
  'sw.js',
  'main.dart.js',
  'version.json',
  'canvaskit/canvaskit.js',
  'canvaskit/canvaskit.wasm',
  'canvaskit/chromium/canvaskit.wasm',
  'canvaskit/webparagraph/canvaskit.wasm',
  'icons/Icon-192.png',
  'icons/Icon-512.png',
  'icons/Icon-maskable-192.png',
  'icons/Icon-maskable-512.png'
];

self.addEventListener('install', (event) => {
  self.skipWaiting();
  event.waitUntil(
    caches.open(CACHE_NAME).then(async (cache) => {
      for (const asset of PRECACHE_ASSETS) {
        try {
          await cache.add(asset);
        } catch (e) {
          console.warn('[SW] Precache skipped for:', asset, e);
        }
      }
    })
  );
});

self.addEventListener('activate', (event) => {
  event.waitUntil(
    caches.keys().then((cacheNames) => {
      return Promise.all(
        cacheNames.map((name) => {
          if (name !== CACHE_NAME) {
            console.log('[SW] Purging old cache:', name);
            return caches.delete(name);
          }
        })
      );
    }).then(() => self.clients.claim())
  );
});

self.addEventListener('fetch', (event) => {
  const url = new URL(event.request.url);

  // 1. NEVER cache Firebase RTDB or local backend APIs - let them fail naturally when offline
  if (
    url.hostname.includes('firebaseio.com') ||
    url.pathname.includes('/api/') ||
    event.request.method !== 'GET'
  ) {
    return;
  }

  // 2. Intercept any external CanvasKit CDN requests and serve local cached CanvasKit instead!
  if (url.hostname.includes('gstatic.com') && url.pathname.includes('canvaskit')) {
    const filename = url.pathname.split('/').pop();
    event.respondWith(
      caches.match(`canvaskit/${filename}`, { ignoreSearch: true }).then((cached) => {
        if (cached) return cached;
        return caches.match('canvaskit/canvaskit.wasm', { ignoreSearch: true }).then((fallback) => {
          return fallback || fetch(event.request);
        });
      })
    );
    return;
  }

  // 3. Cache Google Fonts (Cairo)
  if (url.hostname.includes('fonts.googleapis.com') || url.hostname.includes('fonts.gstatic.com')) {
    event.respondWith(
      caches.match(event.request, { ignoreSearch: true }).then((cached) => {
        if (cached) return cached;
        return fetch(event.request).then((res) => {
          if (res && res.status === 200) {
            const clone = res.clone();
            caches.open(CACHE_NAME).then((cache) => cache.put(event.request, clone));
          }
          return res;
        }).catch(() => {
          // If offline and font css fails, return empty css response rather than failing
          return new Response('', { status: 200, headers: { 'Content-Type': 'text/css' } });
        });
      })
    );
    return;
  }

  // 4. Navigation & HTML: Network-first with Cache-fallback (with ignoreSearch: true)
  if (
    event.request.mode === 'navigate' ||
    url.pathname.endsWith('index.html') ||
    url.pathname.endsWith('/')
  ) {
    event.respondWith(
      fetch(event.request)
        .then((networkResponse) => {
          if (networkResponse && networkResponse.status === 200) {
            const responseClone = networkResponse.clone();
            caches.open(CACHE_NAME).then((cache) => cache.put(event.request, responseClone));
          }
          return networkResponse;
        })
        .catch(async () => {
          const cachedResponse = await caches.match(event.request, { ignoreSearch: true });
          if (cachedResponse) return cachedResponse;
          const fallback = await caches.match('index.html', { ignoreSearch: true });
          if (fallback) return fallback;
          return caches.match('./', { ignoreSearch: true });
        })
    );
    return;
  }

  // 5. All static scripts, bootstrap, flutter, WASM, images: Cache-first with ignoreSearch: true
  event.respondWith(
    caches.match(event.request, { ignoreSearch: true }).then((cachedResponse) => {
      if (cachedResponse) {
        return cachedResponse;
      }

      // If not in cache, fetch from network and store in cache for offline use
      return fetch(event.request)
        .then((networkResponse) => {
          if (networkResponse && networkResponse.status === 200) {
            const responseClone = networkResponse.clone();
            caches.open(CACHE_NAME).then((cache) => cache.put(event.request, responseClone));
          }
          return networkResponse;
        })
        .catch(async (err) => {
          // Fallback for bootstrap or main scripts matching by filename
          const filename = url.pathname.split('/').pop();
          if (filename) {
            const fallback = await caches.match(filename, { ignoreSearch: true });
            if (fallback) return fallback;
          }
          throw err;
        });
    })
  );
});
