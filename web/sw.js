const CACHE_NAME = 'elite-grand-v2';

// Static core assets to pre-cache on install
const PRECACHE_ASSETS = [
  './',
  'index.html',
  'manifest.json',
  'favicon.png',
  'flutter.js',
  'flutter_bootstrap.js',
  'main.dart.js',
  'version.json',
  'canvaskit/canvaskit.js',
  'canvaskit/canvaskit.wasm',
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
          console.warn('[SW] Precache skipped for optional asset:', asset, e);
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
          if (name !== CACHE_NAME && name.startsWith('elite-grand-')) {
            console.log('[SW] Deleting old cache:', name);
            return caches.delete(name);
          }
        })
      );
    }).then(() => self.clients.claim())
  );
});

self.addEventListener('fetch', (event) => {
  const url = new URL(event.request.url);

  // 1. Never cache Firebase RTDB, API endpoints, or WebSockets - let them fail naturally when offline
  if (
    url.hostname.includes('firebaseio.com') ||
    url.hostname.includes('googleapis.com') && url.pathname.includes('/v1/') ||
    url.pathname.includes('/api/') ||
    event.request.method !== 'GET'
  ) {
    return;
  }

  // 2. Network-first with Cache-fallback for HTML and bootstrap scripts (so users always get fresh code if online)
  if (
    event.request.mode === 'navigate' ||
    url.pathname.endsWith('index.html') ||
    url.pathname.endsWith('/') ||
    url.pathname.includes('flutter_bootstrap.js')
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
          const cachedResponse = await caches.match(event.request);
          if (cachedResponse) return cachedResponse;
          const fallback = await caches.match('index.html');
          if (fallback) return fallback;
          return caches.match('./');
        })
    );
    return;
  }

  // 3. Cache-first with background revalidation for JS, WASM, CSS, Fonts, Images
  event.respondWith(
    caches.match(event.request).then((cachedResponse) => {
      if (cachedResponse) {
        // Fetch in background to update cache for next time
        fetch(event.request)
          .then((networkResponse) => {
            if (networkResponse && networkResponse.status === 200) {
              caches.open(CACHE_NAME).then((cache) => cache.put(event.request, networkResponse));
            }
          })
          .catch(() => {});
        return cachedResponse;
      }

      // If not in cache, fetch from network and store in cache
      return fetch(event.request)
        .then((networkResponse) => {
          if (networkResponse && networkResponse.status === 200) {
            const responseClone = networkResponse.clone();
            caches.open(CACHE_NAME).then((cache) => cache.put(event.request, responseClone));
          }
          return networkResponse;
        })
        .catch((err) => {
          // If offline and request is an image or font, ignore or handle gracefully
          console.warn('[SW] Fetch failed offline for:', event.request.url);
          throw err;
        });
    })
  );
});
