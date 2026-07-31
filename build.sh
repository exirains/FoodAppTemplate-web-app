#!/bin/bash

set -e

echo "Installing Flutter..."

git clone https://github.com/flutter/flutter.git -b stable --depth 1

export PATH="$PATH:$PWD/flutter/bin"

echo "Flutter version:"
flutter --version

echo "Enabling Flutter web..."

flutter config --enable-web

echo "Installing dependencies..."

flutter pub get

echo "Building Sangak web..."

flutter build web --release

echo "Build finished successfully!"