#!/bin/bash

echo "🗑️  Uninstalling Battery Limiter..."
echo "=================================="

# Remove the app
if [ -d "/Applications/BatteryLimiter.app" ]; then
    echo "📦 Removing BatteryLimiter.app..."
    sudo rm -rf "/Applications/BatteryLimiter.app"
fi

# Remove launch agent
LAUNCH_AGENT_PATH="$HOME/Library/LaunchAgents/com.batterylimiter.plist"
if [ -f "$LAUNCH_AGENT_PATH" ]; then
    echo "🔌 Removing launch agent..."
    
    # Unload the launch agent first
    launchctl unload "$LAUNCH_AGENT_PATH" 2>/dev/null
    
    # Remove the plist file
    rm -f "$LAUNCH_AGENT_PATH"
fi

echo "✅ Uninstallation complete!"
echo "💡 You may need to restart your Mac for all changes to take effect."
