#!/bin/bash
# -e stops on first error, -x prints every command to the logs for debugging
set -ex

# 1. Fix Git "dubious ownership" errors in CI environments
git config --global --add safe.directory '*'

export PUB_CACHE="$PWD/.pub-cache"

# 2. Clone Flutter (if not cached)
if [ ! -d "flutter" ]; then
  echo "Installing Flutter..."
  git clone https://github.com/flutter/flutter.git -b stable --depth 1
fi

export PATH="$PATH:$PWD/flutter/bin"

# 3. Force Flutter to download the Dart SDK and web binaries before doing anything else
echo "Pre-caching Flutter web binaries..."
flutter precache --web

echo "Flutter version:"
flutter --version

echo "Installing dependencies..."
flutter pub get

# 3.5. Generate .env from Cloudflare Pages environment variables
# Smartly handle if variables already contain "KEY="
write_env_var() {
  local var_name=$1
  local var_val=$2
  if [[ "$var_val" == "$var_name="* ]]; then
    echo "$var_val" >> .env
  else
    echo "$var_name=$var_val" >> .env
  fi
}

printf "" > .env
write_env_var "SUPABASE_URL" "$SUPABASE_URL"
write_env_var "SUPABASE_PUBLISHABLE_KEY" "$SUPABASE_PUBLISHABLE_KEY"
write_env_var "GOOGLE_WEB_CLIENT_ID" "$GOOGLE_WEB_CLIENT_ID"
write_env_var "GEOAPIFY_API_KEY" "$GEOAPIFY_API_KEY"

echo "Building Babka web..."
flutter build web --release -v

# 4. PWA Support: Create a minimal service worker that allows "Add to Home Screen"
# without caching assets (avoiding stale content/update risks).
cat > build/web/flutter_service_worker.js << 'EOF'
const CACHE_NAME = 'Babka-v1';

self.addEventListener('install', (event) => {
  self.skipWaiting();
});

self.addEventListener('activate', (event) => {
  event.waitUntil(
    caches.keys().then((cacheNames) => {
      return Promise.all(
        cacheNames.map((cacheName) => {
          if (cacheName !== CACHE_NAME) {
            return caches.delete(cacheName);
          }
        })
      );
    })
  );
});

// Network-first strategy: Always try to fetch from network first.
// This ensures users always see the latest version when online.
self.addEventListener('fetch', (event) => {
  event.respondWith(
    fetch(event.request).catch(() => {
      return caches.match(event.request);
    })
  );
});
EOF

# 5. Ensure manifest.json is present (do NOT remove it)
# We make sure it exists in the build folder
cp web/manifest.json build/web/manifest.json

echo "Build finished successfully!"

