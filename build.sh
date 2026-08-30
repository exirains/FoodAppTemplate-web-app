#!/bin/bash
set -ex

# Ensure a clean start for CI
rm -rf build/web

git config --global --add safe.directory '*'
export PUB_CACHE="$PWD/.pub-cache"

# Clone Flutter only if missing (Cloudflare might persist cache between builds)
if [ ! -d "flutter" ]; then
  echo "Installing Flutter..."
  git clone https://github.com/flutter/flutter.git -b stable --depth 1
fi

export PATH="$PATH:$PWD/flutter/bin"

echo "Setting up Flutter environment..."
flutter config --no-analytics
flutter config --enable-web

echo "Fetching dependencies..."
# Use --offline if you are sure they exist, but on CI we need to fetch
flutter pub get

echo "GENERATING LOCALIZATION..."
# This is the critical step that usually causes 'Failed to compile'
# if localization imports are missing.
flutter gen-l10n

# Build the .env file from Cloudflare Environment Variables
printf "" > .env
if [ -n "$SUPABASE_URL" ]; then echo "SUPABASE_URL=$SUPABASE_URL" >> .env; fi
if [ -n "$SUPABASE_PUBLISHABLE_KEY" ]; then echo "SUPABASE_PUBLISHABLE_KEY=$SUPABASE_PUBLISHABLE_KEY" >> .env; fi
if [ -n "$GOOGLE_WEB_CLIENT_ID" ]; then echo "GOOGLE_WEB_CLIENT_ID=$GOOGLE_WEB_CLIENT_ID" >> .env; fi
if [ -n "$GEOAPIFY_API_KEY" ]; then echo "GEOAPIFY_API_KEY=$GEOAPIFY_API_KEY" >> .env; fi

echo "COMPILING FOR WEB..."
# --web-renderer html is lighter on memory, which prevents CI crashes.
flutter build web --release --no-tree-shake-icons --web-renderer html --no-pub --verbose

echo "Build finished successfully!"