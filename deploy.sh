#!/bin/bash

# 🚀 Student Records Webapp - Deployment Script
# This script helps you prepare and deploy your Flutter web app

echo "🎯 Student Records Webapp - Deployment Preparation"
echo "================================================="

# Check if Flutter is installed
if ! command -v flutter &> /dev/null; then
    echo "❌ Flutter is not installed or not in PATH"
    echo "Please install Flutter: https://flutter.dev/docs/get-started/install"
    exit 1
fi

echo "✅ Flutter found: $(flutter --version | head -n 1)"

# Check if we're in the right directory
if [ ! -f "pubspec.yaml" ]; then
    echo "❌ pubspec.yaml not found. Please run this script from your Flutter project root."
    exit 1
fi

echo "✅ Flutter project detected"

# Get Flutter dependencies
echo "📦 Getting Flutter dependencies..."
flutter pub get

# Check for any issues
echo "🔍 Checking for issues..."
flutter analyze

# Build for web
echo "🏗️  Building for web (release mode)..."
flutter build web --release

# Check if build was successful
if [ -d "build/web" ]; then
    echo "✅ Web build successful!"
    echo "📁 Build output: build/web/"
    
    # Show build size
    BUILD_SIZE=$(du -sh build/web | cut -f1)
    echo "📊 Build size: $BUILD_SIZE"
    
    echo ""
    echo "🎉 Your app is ready for deployment!"
    echo ""
    echo "📋 Next steps:"
    echo "1. Push your code to GitHub"
    echo "2. Connect GitHub repo to Netlify"
    echo "3. Deploy automatically!"
    echo ""
    echo "📖 See DEPLOYMENT_GUIDE.md for detailed instructions"
    
else
    echo "❌ Build failed. Please check the error messages above."
    exit 1
fi

echo ""
echo "🚀 Happy deploying!"
