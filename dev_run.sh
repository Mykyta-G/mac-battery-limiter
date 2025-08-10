#!/bin/bash

# Battery Limiter - Development Environment Runner
# This script builds and runs the app locally for development/testing
# WITHOUT installing it system-wide

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Project configuration
PROJECT_NAME="BatteryLimiter"
SCHEME="BatteryLimiter"
CONFIGURATION="Debug"
BUILD_DIR="build/dev"
APP_NAME="BatteryLimiter.app"

echo -e "${BLUE}🔋 Battery Limiter - Development Environment${NC}"
echo -e "${BLUE}=============================================${NC}"
echo ""

# Function to cleanup on exit
cleanup() {
    echo ""
    echo -e "${YELLOW}🧹 Cleaning up development environment...${NC}"
    
    # Kill any running instances
    pkill -f "BatteryLimiter" 2>/dev/null || true
    
    # Remove build directory
    if [ -d "$BUILD_DIR" ]; then
        echo -e "${YELLOW}🗑️  Removing build directory...${NC}"
        rm -rf "$BUILD_DIR"
    fi
    
    echo -e "${GREEN}✅ Development environment cleaned up!${NC}"
}

# Set up cleanup trap
trap cleanup EXIT

# Check if Xcode is installed
if ! command -v xcodebuild &> /dev/null; then
    echo -e "${RED}❌ Xcode is not installed or not in PATH${NC}"
    echo "Please install Xcode from the App Store and try again."
    exit 1
fi

# Check project structure
echo -e "${BLUE}🔍 Checking project structure...${NC}"
if [ ! -f "BatteryLimiter.xcodeproj/project.pbxproj" ]; then
    echo -e "${RED}❌ BatteryLimiter.xcodeproj not found in current directory${NC}"
    echo "Please run this script from the project root directory."
    exit 1
fi

# Clean up any existing build artifacts
echo -e "${BLUE}🧹 Cleaning hidden files and metadata...${NC}"
if [ -d "$BUILD_DIR" ]; then
    # Remove extended attributes and hidden files
    find "$BUILD_DIR" -type f -exec xattr -c {} \; 2>/dev/null || true
    find "$BUILD_DIR" -name ".*" -delete 2>/dev/null || true
    find "$BUILD_DIR" -name "._*" -delete 2>/dev/null || true
    find "$BUILD_DIR" -name ".DS_Store" -delete 2>/dev/null || true
    
    # Remove build directory completely
    rm -rf "$BUILD_DIR"
fi

# Clean Xcode derived data
echo -e "${BLUE}🧹 Cleaning Xcode derived data...${NC}"
rm -rf ~/Library/Developer/Xcode/DerivedData/* 2>/dev/null || true

# Build the app
echo -e "${BLUE}🏗️  Building Battery Limiter (Debug)...${NC}"
echo "This may take a few minutes on first build..."

# Build with code signing disabled for development
xcodebuild -project BatteryLimiter.xcodeproj \
    -scheme "$SCHEME" \
    -configuration "$CONFIGURATION" \
    -derivedDataPath "$BUILD_DIR" \
    -skipPackagePluginValidation \
    -skipMacroValidation \
    CODE_SIGN_IDENTITY="" \
    CODE_SIGNING_REQUIRED=NO \
    CODE_SIGNING_ALLOWED=NO \
    build

# Check if build was successful
if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ Build successful!${NC}"
    
    # Check if the app was created
    if [ -d "$BUILD_DIR/Build/Products/$CONFIGURATION/$APP_NAME" ]; then
        echo -e "${GREEN}🎉 App built successfully!${NC}"
        echo -e "${BLUE}📱 App location: $BUILD_DIR/Build/Products/$CONFIGURATION/$APP_NAME${NC}"
        
        # Run the app
        echo -e "${BLUE}🚀 Launching Battery Limiter...${NC}"
        open "$BUILD_DIR/Build/Products/$CONFIGURATION/$APP_NAME"
        
        echo ""
        echo -e "${GREEN}✅ Battery Limiter is now running!${NC}"
        echo -e "${YELLOW}💡 To stop the app, close it manually or press Ctrl+C in this terminal${NC}"
        
        # Wait for user to stop
        echo ""
        echo -e "${BLUE}Press Ctrl+C to stop the development environment...${NC}"
        while true; do
            sleep 1
        done
    else
        echo -e "${RED}❌ App not found after build${NC}"
        echo "Expected location: $BUILD_DIR/Build/Products/$CONFIGURATION/$APP_NAME"
        exit 1
    fi
else
    echo -e "${RED}❌ Build failed${NC}"
    exit 1
fi
