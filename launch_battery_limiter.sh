#!/bin/bash

echo "🔋 Launching Battery Limiter..."
echo "================================"

# Check if the app is installed in Applications
APP_PATH="/Applications/BatteryLimiter.app"

if [ -d "$APP_PATH" ]; then
    echo "✅ Found Battery Limiter in Applications"
    
    # Check if the app is already running
    if pgrep -f "BatteryLimiter" > /dev/null; then
        echo "⚠️  Battery Limiter is already running"
        echo "💡 You can find it in your menu bar (battery icon)"
        
        # Bring the app to front if it's running
        osascript -e 'tell application "BatteryLimiter" to activate'
    else
        echo "🚀 Launching Battery Limiter..."
        open "$APP_PATH"
        
        # Wait a moment for the app to start
        sleep 2
        
        # Check if it's running
        if pgrep -f "BatteryLimiter" > /dev/null; then
            echo "✅ Battery Limiter launched successfully!"
            echo "💡 Look for the battery icon in your menu bar"
        else
            echo "❌ Failed to launch Battery Limiter"
            echo "💡 Check System Preferences > Security & Privacy > Accessibility"
        fi
    fi
else
    echo "❌ Battery Limiter not found in Applications"
    echo ""
    echo "🔧 To install Battery Limiter:"
    echo "   1. Run: ./build.sh"
    echo "   2. Then: cd BatteryLimiter-Standalone && ./install.sh"
    echo ""
    echo "💡 Or manually copy BatteryLimiter.app to your Applications folder"
fi

echo ""
echo "📱 Battery Limiter will:"
echo "   - Run automatically at login"
echo "   - Continue monitoring during sleep"
echo "   - Show notifications when battery reaches limits"
echo "   - Run independently without Xcode"
