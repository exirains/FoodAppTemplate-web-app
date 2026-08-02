#!/bin/bash
set -e

# Define custom pub cache directory inside the project root
export PUB_CACHE="$PWD/.pub-cache"

if [ ! -d "flutter" ]; then
  echo "Installing Flutter..."
  git clone https://github.com/flutter/flutter.git -b stable --depth 1
fi

export PATH="$PATH:$PWD/flutter/bin"

echo "Flutter version:"
flutter --version

echo "Installing dependencies..."
flutter pub get

# Ensure .env exists so Flutter asset bundling does not fail
if [ ! -f ".env" ]; then
  echo "Creating dummy .env file for build..."
  touch .env
fi

echo "Building Sangak web..."
flutter build web --release --pwa-strategy=none

echo "Build finished successfully!"