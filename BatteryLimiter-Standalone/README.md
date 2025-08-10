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
2. Enter your password when prompted
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
