#!/bin/bash
set -e

echo "🎯 Installing Flutter SDK..."
curl -fsSL https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_3.24.5-stable.tar.xz | tar -xz

echo "📦 Setting up Flutter..."
export PATH="$PATH:$(pwd)/flutter/bin"

echo "🔧 Configuring Flutter for web..."
flutter config --enable-web

echo "📚 Getting dependencies..."
flutter pub get

echo "🏗️ Building Flutter web app..."
flutter build web --release

echo "✅ Build completed successfully!"