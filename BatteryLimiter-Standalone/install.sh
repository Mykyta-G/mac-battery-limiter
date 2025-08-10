#!/bin/bash

echo "🔋 Installing Battery Limiter..."
echo "================================"

# Check if we're on macOS
if [[ "$OSTYPE" != "darwin"* ]]; then
    echo "❌ Error: This script must be run on macOS"
    exit 1
fi

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APP_PATH="$SCRIPT_DIR/BatteryLimiter.app"

if [ ! -d "$APP_PATH" ]; then
    echo "❌ Error: BatteryLimiter.app not found in $SCRIPT_DIR"
    exit 1
fi

# Check if app is already installed
if [ -d "/Applications/BatteryLimiter.app" ]; then
    echo "⚠️  Battery Limiter is already installed. Removing old version..."
    
    # Check if we have permission to remove from Applications
    if [[ ! -w "/Applications" ]]; then
        echo "❌ Error: No permission to write to /Applications folder"
        echo "💡 Please run with sudo or check your permissions"
        exit 1
    fi
    
    rm -rf "/Applications/BatteryLimiter.app"
fi

# Install the app
echo "📦 Installing Battery Limiter to Applications..."
cp -R "$APP_PATH" "/Applications/"

# Set proper permissions (only if we have admin access)
if [[ -w "/Applications/BatteryLimiter.app" ]]; then
    echo "🔐 Setting proper permissions..."
    chown -R "$(whoami):staff" "/Applications/BatteryLimiter.app"
    chmod -R 755 "/Applications/BatteryLimiter.app"
else
    echo "⚠️  Could not set permissions - app may need to be moved manually"
fi

echo "✅ Installation complete!"
echo ""
echo "🚀 To launch the app:"
echo "   - Double-click BatteryLimiter.app in Applications folder"
echo "   - Or use: open /Applications/BatteryLimiter.app"
echo ""
echo "💡 The app will automatically start at login and run in the background."
echo "   Look for the battery icon in your menu bar!"
echo ""
echo "🔧 To uninstall:"
echo "   ./uninstall.sh"
