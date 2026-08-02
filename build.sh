#!/bin/bash

set -e

if [ ! -d "flutter" ]; then
  echo "Installing Flutter..."
  git clone https://github.com/flutter/flutter.git -b stable --depth 1
fi

export PATH="$PATH:$PWD/flutter/bin"

echo "Flutter version:"
flutter --version

echo "Enabling Flutter web..."
flutter config --enable-web

echo "Installing dependencies..."
flutter pub get

echo "Building Sangak web..."
flutter build web --release --pwa-strategy=none

echo "Build finished successfully!"