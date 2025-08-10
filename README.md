# Battery Limiter for macOS

A macOS menu bar application that helps preserve your Mac's battery health by monitoring charging levels and providing intelligent charging recommendations.

## Features

- **Battery Monitoring**: Real-time monitoring of battery level, charging status, and power source
- **Smart Charging Limits**: Set custom maximum charge limits (20%-100%) to prevent overcharging
- **Menu Bar Integration**: Easy access from the menu bar with an orange battery icon
- **Background Operation**: Continues monitoring even when the app is not actively used
- **Sleep Mode Support**: Maintains monitoring during system sleep with reduced frequency
- **Auto-start**: Option to automatically start with your Mac
- **Notifications**: Alerts when battery reaches your set limit
- **Accessibility Permissions**: Uses system permissions to monitor battery status

## System Requirements

- macOS 14.0 or later
- Intel or Apple Silicon Mac
- Accessibility permissions (required for battery monitoring)

## Installation

### Quick Start (Recommended)

The easiest way to get Battery Limiter running:

```bash
# Clone the repository
git https://github.com/Mykyta-G/mac-battery-limiter.git
cd mac-battery-limiter

# Run the automated setup script
./run_app.sh
```

This script will automatically:
1. Check if the app is already built
2. Build it if needed using Xcode command line tools
3. Install it to your Applications folder
4. Launch the app

### Manual Installation

If you prefer step-by-step control:

```bash
# 1. Build the standalone app
./build.sh

# 2. Install to Applications folder
cd BatteryLimiter-Standalone
./install.sh
cd ..

# 3. Launch the app
./launch_battery_limiter.sh
```

### Requirements

- macOS 14.0 or later
- Xcode command line tools (for building)
- Accessibility permissions (granted when first run)

## Usage

### First Run

1. **Run the setup script**: `./run_app.sh` (this handles building, installing, and launching)
2. **Grant permissions**: When prompted, allow accessibility permissions for battery monitoring
3. **Find the app**: Look for the orange battery icon in your menu bar (top-right of screen)

### Daily Use

1. **Menu Bar Access**: Click the orange battery icon in your menu bar
2. **Set Charge Limit**: Adjust the slider to your preferred maximum charge level (20%-100%)
3. **Monitor Status**: View real-time battery information and charging status
4. **Automatic Operation**: The app runs in the background and notifies you when limits are reached

### App Features

- **Background Monitoring**: Continues working even when not actively used
- **Sleep Mode Support**: Maintains monitoring during system sleep
- **Auto-start**: Automatically launches when you log into your Mac
- **Notifications**: Alerts when battery reaches your set limit

## Privacy & Permissions

Battery Limiter requires accessibility permissions to:
- Monitor battery status and charging information
- Provide accurate battery health recommendations
- Operate in the background for continuous monitoring

No personal data is collected or transmitted. All monitoring is performed locally on your device.

## Technical Details

- Built with SwiftUI and AppKit
- Uses IOKit for battery information access
- Implements LaunchAgent for auto-start functionality
- Supports both Intel and Apple Silicon Macs
- Optimized for background operation with minimal resource usage
- **Command-line build system** with automated scripts for easy deployment
- **Standalone app distribution** - no Xcode required after initial build

## Contributing

Contributions are welcome! Please feel free to submit pull requests or open issues for bugs and feature requests.

## License

Copyright © 2024 Battery Limiter. All rights reserved.

## Support

For support, please open an issue in this repository or contact the development team.

---

**Note**: This app is designed to help preserve battery health by providing information and recommendations. It does not directly control charging hardware, which would require additional system-level permissions.
