#!/bin/bash

echo "🔋 Building Battery Limiter Standalone App..."
echo "=============================================="

# Check if we're on macOS
if [[ "$OSTYPE" != "darwin"* ]]; then
    echo "❌ Error: This script must be run on macOS"
    exit 1
fi

# Check if Xcode is installed
if ! command -v xcodebuild &> /dev/null; then
    echo "❌ Error: xcodebuild not found. Please install Xcode first."
    echo "💡 Run: xcode-select --install"
    exit 1
fi

# Check if we have write permissions to the current directory
if [[ ! -w "." ]]; then
    echo "❌ Error: No write permission in current directory"
    exit 1
fi

# Clean previous builds
echo "🧹 Cleaning previous builds..."
xcodebuild -project BatteryLimiter.xcodeproj -scheme BatteryLimiter clean

# Build the project in Release mode for better performance
echo "📦 Building project in Release mode..."
xcodebuild -project BatteryLimiter.xcodeproj -scheme BatteryLimiter -configuration Release build

if [ $? -eq 0 ]; then
    echo "✅ Build successful!"
    
    # Find the built app
    APP_PATH=$(find ~/Library/Developer/Xcode/DerivedData -name "BatteryLimiter.app" -path "*/Build/Products/Release/*" -not -path "*/Index.noindex/*" 2>/dev/null | head -1)
    
    if [ -n "$APP_PATH" ]; then
        echo "📍 Found app at: $APP_PATH"
        
        # Create standalone app directory
        STANDALONE_DIR="./BatteryLimiter-Standalone"
        mkdir -p "$STANDALONE_DIR"
        
        # Copy the app to standalone directory
        cp -R "$APP_PATH" "$STANDALONE_DIR/"
        
        # Create installation script
        cat > "$STANDALONE_DIR/install.sh" << 'EOF'
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
EOF

        # Make install script executable
        chmod +x "$STANDALONE_DIR/install.sh"
        
        # Create uninstall script
        cat > "$STANDALONE_DIR/uninstall.sh" << 'EOF'
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
EOF

        # Make uninstall script executable
        chmod +x "$STANDALONE_DIR/uninstall.sh"
        
        # Create README for standalone
        cat > "$STANDALONE_DIR/README.md" << 'EOF'
# Battery Limiter - Standalone Installation

## What is Battery Limiter?
Battery Limiter is a macOS app that helps preserve your MacBook's battery health by limiting the maximum charge level. It runs in the background and automatically manages charging to keep your battery between 20-80% for optimal longevity.

## Features
- 🚀 **Automatic startup**: Runs automatically when you boot your Mac
- 🌙 **Sleep mode support**: Continues monitoring even when Mac is asleep
- 🔋 **Smart charging**: Automatically stops charging at your set limit
- 📱 **Menu bar access**: Easy access via the battery icon in your menu bar
- ⚙️ **Customizable limits**: Set your preferred maximum charge percentage

## Installation

### Option 1: Automatic Installation (Recommended)
1. Double-click `install.sh` in this folder
2. Enter your password when prompted (if needed)
3. The app will be installed to your Applications folder
4. Launch the app from Applications or it will start automatically at login

### Option 2: Manual Installation
1. Copy `BatteryLimiter.app` to your Applications folder
2. Launch the app from Applications
3. Grant accessibility permissions when prompted

## Usage
- The app runs automatically in the background
- Look for the battery icon in your menu bar
- Click the icon to access settings and battery information
- The app will automatically start at login

## Uninstallation
Run `uninstall.sh` to completely remove the app and all associated files.

## Troubleshooting
- If the menu bar icon doesn't appear, check System Preferences > Security & Privacy > Accessibility
- Ensure the app has accessibility permissions
- Restart the app if needed: `killall BatteryLimiter && open /Applications/BatteryLimiter.app`

## System Requirements
- macOS 10.15 (Catalina) or later
- Intel or Apple Silicon Mac
- Accessibility permissions (required for battery monitoring)

## Support
For issues or questions, check the app's built-in help or contact support.
EOF

        echo "✅ Standalone app package created successfully!"
        echo ""
        echo "📁 Files created in: $STANDALONE_DIR"
        echo "🔧 To install: cd $STANDALONE_DIR && ./install.sh"
        echo "🗑️  To uninstall: cd $STANDALONE_DIR && ./uninstall.sh"
        
    else
        echo "❌ Error: Built app not found. Build may have failed."
        exit 1
    fi
    
else
    echo "❌ Build failed. Please check for errors in Xcode."
    exit 1
fi
