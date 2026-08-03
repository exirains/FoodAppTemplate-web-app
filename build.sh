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

echo "Building Sangak web..."
# 4. Added -v (verbose) so if the build fails, the CI logs will tell you exactly why
flutter build web --release -v

echo "Build finished successfully!"