#!/bin/bash

echo "🗑️  Uninstalling Battery Limiter..."
echo "=================================="

# Check if we're on macOS
if [[ "$OSTYPE" != "darwin"* ]]; then
    echo "❌ Error: This script must be run on macOS"
    exit 1
fi

# Remove the app
if [ -d "/Applications/BatteryLimiter.app" ]; then
    echo "📦 Removing BatteryLimiter.app..."
    
    # Check if we have permission to remove from Applications
    if [[ ! -w "/Applications" ]]; then
        echo "❌ Error: No permission to write to /Applications folder"
        echo "💡 Please run with sudo or check your permissions"
        exit 1
    fi
    
    rm -rf "/Applications/BatteryLimiter.app"
    echo "✅ App removed successfully"
else
    echo "ℹ️  App not found in Applications folder"
fi

# Remove launch agent
LAUNCH_AGENT_PATH="$HOME/Library/LaunchAgents/com.batterylimiter.app.plist"
if [ -f "$LAUNCH_AGENT_PATH" ]; then
    echo "🔌 Removing launch agent..."
    
    # Unload the launch agent first
    launchctl unload "$LAUNCH_AGENT_PATH" 2>/dev/null || true
    
    # Remove the plist file
    rm -f "$LAUNCH_AGENT_PATH"
    echo "✅ Launch agent removed successfully"
else
    echo "ℹ️  Launch agent not found"
fi

echo ""
echo "✅ Uninstallation complete!"
echo "💡 You may need to restart your Mac for all changes to take effect."
