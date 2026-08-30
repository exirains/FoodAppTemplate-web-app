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

echo "Configuring Flutter..."
flutter config --no-analytics
flutter config --enable-web

echo "Pre-caching Flutter web binaries..."
flutter precache --web

echo "Installing dependencies..."
flutter pub get

echo "Generating localization..."
flutter gen-l10n

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
# 1. Use --web-renderer html for maximum compatibility in CI environments
# 2. Use --no-pub because we already ran it
# 3. Use --verbose to catch hidden errors if it fails again
flutter build web --release --no-tree-shake-icons --web-renderer html --no-pub --verbose

# Copy manifest safely if needed (Flutter usually handles this, but we'll ensure it)
if [ -f "web/manifest.json" ] && [ -d "build/web" ]; then
  cp web/manifest.json build/web/manifest.json
fi

echo "Build finished successfully!"
