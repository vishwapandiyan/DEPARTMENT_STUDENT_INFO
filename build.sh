#!/bin/bash

# 🚀 Flutter Web Build Script for Netlify
echo "🎯 Starting Flutter Web Build for Netlify..."

# Install Flutter SDK
echo "📦 Installing Flutter SDK..."
curl -o flutter_linux.tar.xz https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_3.24.5-stable.tar.xz
tar xf flutter_linux.tar.xz
export PATH="$PATH:/opt/build/repo/flutter/bin"

# Set up Flutter
echo "⚙️ Setting up Flutter..."
flutter doctor --android-licenses || true
flutter config --enable-web

# Get dependencies
echo "📚 Getting Flutter dependencies..."
flutter pub get

# Build for web
echo "🏗️ Building Flutter web app..."
flutter build web --release

echo "✅ Build completed successfully!"
