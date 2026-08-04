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
echo "SUPABASE_URL=$SUPABASE_URL" > .env
echo "SUPABASE_PUBLISHABLE_KEY=$SUPABASE_PUBLISHABLE_KEY" >> .env
echo "GOOGLE_WEB_CLIENT_ID=$GOOGLE_WEB_CLIENT_ID" >> .env
echo "GEOAPIFY_API_KEY=$GEOAPIFY_API_KEY" >> .env

echo "Building Sangak web..."
flutter build web --release -v

# 4. Kill-switch: unregister any previously installed service worker for existing users
cat > build/web/flutter_service_worker.js << 'EOF'
self.addEventListener('install', () => self.skipWaiting());
self.addEventListener('activate', (event) => {
  event.waitUntil(
    caches.keys()
      .then((keys) => Promise.all(keys.map((key) => caches.delete(key))))
      .then(() => self.registration.unregister())
      .then(() => self.clients.matchAll())
      .then((clients) => clients.forEach((c) => c.navigate(c.url))))
  );
});
EOF

# 5. Remove potential PWA artifacts to ensure clean browser behavior
rm -f build/web/manifest.json

echo "Build finished successfully!"
