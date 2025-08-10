#!/bin/bash

echo "🔋 Installing Battery Limiter..."
echo "================================"

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
    sudo rm -rf "/Applications/BatteryLimiter.app"
fi

# Install the app
echo "📦 Installing Battery Limiter to Applications..."
sudo cp -R "$APP_PATH" "/Applications/"

# Set proper permissions
sudo chown -R root:wheel "/Applications/BatteryLimiter.app"
sudo chmod -R 755 "/Applications/BatteryLimiter.app"

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
echo "   sudo rm -rf /Applications/BatteryLimiter.app"
echo "   rm -rf ~/Library/LaunchAgents/com.batterylimiter.plist"
