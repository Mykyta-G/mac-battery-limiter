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

### From Source

1. Clone this repository
2. Open `BatteryLimiter.xcodeproj` in Xcode
3. Build and run the project
4. Grant accessibility permissions when prompted

### Building for Distribution

1. Open the project in Xcode
2. Select Product → Archive
3. Follow the distribution process for your target platform

## Usage

1. **Launch the App**: The app will appear in your menu bar with an orange battery icon
2. **Set Charge Limit**: Click the menu bar icon and adjust the slider to your preferred maximum charge level
3. **Monitor Status**: View real-time battery information and charging status
4. **Automatic Operation**: The app will automatically monitor and notify you when limits are reached

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

## Contributing

Contributions are welcome! Please feel free to submit pull requests or open issues for bugs and feature requests.

## License

Copyright © 2024 Battery Limiter. All rights reserved.

## Support

For support, please open an issue in this repository or contact the development team.

---

**Note**: This app is designed to help preserve battery health by providing information and recommendations. It does not directly control charging hardware, which would require additional system-level permissions.
