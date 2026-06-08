#!/bin/bash
# Enable error output
set -e

# Disable interactive prompts
export CI=true

echo "Cloning Flutter repository (shallow)..."
git clone https://github.com/flutter/flutter.git -b stable --depth 1

export PATH="$PATH:`pwd`/flutter/bin"

echo "Flutter version:"
flutter --version

echo "Disabling analytics and enabling web..."
flutter config --no-analytics

echo "Running pub get..."
flutter pub get

echo "Building Flutter Web App..."
flutter build web --release --tree-shake-icons --pwa-strategy=none

echo "Build successful!"
