#!/bin/bash
set -e

echo "🎯 Installing Flutter SDK..."
# Download and extract Flutter SDK
curl -fsSL https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_3.24.5-stable.tar.xz | tar -xz

echo "📦 Setting up Flutter..."
# Add Flutter to PATH
export PATH="$PATH:$(pwd)/flutter/bin"

# Verify Flutter installation
flutter --version

# Configure Flutter for web
flutter config --enable-web
flutter config --no-analytics

echo "📚 Getting dependencies..."
flutter pub get

echo "🏗️ Building Flutter web app..."
flutter build web --release --verbose

echo "🔍 Verifying build output..."
if [ -d "build/web" ]; then
    echo "✅ Build successful!"
    ls -la build/web/
else
    echo "❌ Build failed - no output directory"
    exit 1
fi

echo "✅ Build completed successfully!"
