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

echo "Building Sangak web..."
flutter build web --release

echo "Build finished successfully!"