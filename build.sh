#!/bin/bash
set -ex

git config --global --add safe.directory '*'
export PUB_CACHE="$PWD/.pub-cache"

# Clone Flutter only if missing
if [ ! -d "flutter" ]; then
  echo "Installing Flutter..."
  git clone https://github.com/flutter/flutter.git -b stable --depth 1
fi

export PATH="$PATH:$PWD/flutter/bin"

echo "Pre-caching Flutter web binaries..."
flutter precache --web

echo "Installing dependencies..."
flutter pub get

# Safely write .env
write_env_var() {
  local var_name=$1
  local var_val=$2
  if [ -n "$var_val" ]; then
    if [[ "$var_val" == "$var_name="* ]]; then
      echo "$var_val" >> .env
    else
      echo "$var_name=$var_val" >> .env
    fi
  fi
}

printf "" > .env
write_env_var "SUPABASE_URL" "$SUPABASE_URL"
write_env_var "SUPABASE_PUBLISHABLE_KEY" "$SUPABASE_PUBLISHABLE_KEY"
write_env_var "GOOGLE_WEB_CLIENT_ID" "$GOOGLE_WEB_CLIENT_ID"
write_env_var "GEOAPIFY_API_KEY" "$GEOAPIFY_API_KEY"

echo "Building Flutter Web..."
flutter build web --release --no-tree-shake-icons

# Create web dir if flutter build didn't auto-create it
mkdir -p build/web

# Write PWA service worker
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

self.addEventListener('fetch', (event) => {
  event.respondWith(
    fetch(event.request).catch(() => {
      return caches.match(event.request);
    })
  );
});
EOF

# Copy manifest safely
if [ -f "web/manifest.json" ]; then
  cp web/manifest.json build/web/manifest.json
else
  echo "Warning: web/manifest.json not found, skipping copy."
fi

echo "Build finished successfully!"