# Battery Limiter

A macOS application that helps preserve your MacBook's battery health by monitoring battery status and providing insights into battery health. 

⚠️ **IMPORTANT: Battery Charging Control is NOT Possible on Modern Macs**

**This app CANNOT stop charging or set charge limits** due to Apple's security restrictions. It provides battery monitoring and health insights instead.

## 🔍 Current Status: Research Complete

**We have thoroughly investigated battery charging control on modern Macs and found it to be fundamentally impossible:**

### **What We Tested:**
- ✅ **SMC Access**: Successfully connected to System Management Controller
- ❌ **Battery Keys**: **NO battery control keys exist** on macOS 15.6+
- ❌ **Write Capability**: Keys cannot be created or modified
- ❌ **Charging Control**: **Zero software methods available**

### **Why It's Impossible:**
1. **Apple Removed the Keys**: Battery control SMC keys don't exist anymore
2. **No Software Interface**: macOS provides no commands for charging control
3. **Firmware Lockdown**: Charging circuits are controlled by locked firmware
4. **Security Design**: Apple intentionally removed this functionality

These tools proved that even with full administrative access, battery charging control is impossible on modern macOS.

## ✨ Features

- **Battery Monitoring**: Real-time battery level and charging status
- **Battery Health Insights**: Information about battery condition and cycle count
- **Menu Bar Integration**: Easy access via the battery icon in your menu bar
- **Background Operation**: Continues monitoring even when the app is not actively used
- **Sleep Mode Support**: Maintains monitoring during system sleep with reduced frequency
- **Automatic Startup**: Launches automatically when you boot your Mac
- **System Compatibility Detection**: Automatically detects your Mac's capabilities
- **Accessibility Permissions**: Uses system permissions to monitor battery status
- **🆕 Enhanced Monitoring**: Comprehensive battery status with detailed information
- **🆕 System Insights**: Shows what battery control methods are available on your Mac
- **🆕 Polished UI/UX**: Clean, modern interface with optimal spacing and layout for the best user experience

## 🚀 Quick Start

### **Option 1: Production Installation (Recommended for Users)**
1. **Clone the repository:**
   ```bash
   git clone https://github.com/yourusername/mac-battery-limiter.git
   cd mac-battery-limiter
   ```

2. **Build and install:**
   ```bash
   ./build.sh
   cd BatteryLimiter-Standalone
   ./install.sh
   ```

### **Option 2: Development Environment (For Developers/Testing)**
Want to test without installing? Use the development environment:

```bash
./dev_run.sh
```

This runs the app locally for testing without system installation. Perfect for:
- 🧪 Testing new features
- 🐛 Debugging issues
- 🔍 Trying before installing
- 🚀 Quick development iterations

See [DEVELOPMENT.md](DEVELOPMENT.md) for full development guide.

3. **Grant permissions**: When prompted, allow accessibility permissions for battery monitoring

4. **Access the app**: Look for the battery icon in your menu bar

## 📋 Requirements

- macOS 10.15 (Catalina) or later
- Intel or Apple Silicon Mac
- Accessibility permissions (required for battery monitoring)

## 🔧 Manual Installation

If you prefer to build manually:

1. **Build the standalone app**
   ```bash
   ./build.sh
   ```

2. **Install to Applications**
   ```bash
   cd BatteryLimiter-Standalone
   ./install.sh
   ```

3. **Launch the app**
   ```bash
   ./launch_battery_limiter.sh
   ```

## 📱 Usage

### First Run
1. The app will request accessibility permissions
2. Set your preferred maximum charge limit (default: 80%)
3. The app starts monitoring automatically

### Daily Use
- **Menu Bar Access**: Click the battery icon in your menu bar
- **Real-time Updates**: Battery status updates automatically every 2 seconds
- **Automatic Operation**: The app runs in the background and notifies you when limits are reached

### Features
- **Background Monitoring**: Continues working even when not actively used
- **Sleep Mode Support**: Maintains monitoring during system sleep
- **Battery Health Notifications**: Alerts about battery status and health
- **System Compatibility Info**: Shows what's possible on your specific Mac

## 🗑️ Uninstallation

To completely remove Battery Limiter:

1. **From the project directory:**
   ```bash
   cd BatteryLimiter-Standalone
   ./uninstall.sh
   ```

2. **Or if you're already in the project root:**
   ```bash
   ./BatteryLimiter-Standalone/uninstall.sh
   ```

The uninstall script will:
- Remove the app from your Applications folder
- Remove the LaunchAgent (so it won't start automatically)
- Clean up all associated files
- Stop the app if it's currently running

## 🔒 Privacy & Permissions

Battery Limiter requires accessibility permissions to:
- Monitor battery status and charging state
- Provide real-time battery information
- Operate in the background for continuous monitoring

**No personal data is collected or transmitted.** All monitoring is done locally on your Mac.

## 🛠️ Technical Details

- **Framework**: SwiftUI + AppKit
- **Battery Monitoring**: IOKit framework with enhanced error handling
- **System Detection**: Automatic macOS version and architecture detection
- **Compatibility Analysis**: Determines what battery control methods are available
- **Background Operation**: LaunchAgent integration with monitoring intervals
- **Command-line build system**: Uses xcodebuild for automated builds
- **Standalone app distribution**: Self-contained installation packages
- **🆕 Enhanced Monitoring**: Comprehensive battery status and health information

## 🚫 Why Battery Charging Control is Impossible

**Battery Limiter cannot stop charging or set charge limits** due to fundamental limitations in modern macOS:

### **🔒 Apple's Security Restrictions**
- **No Software Interface**: macOS provides no commands to control battery charging
- **SMC Lockdown**: System Management Controller keys for battery control are removed
- **Firmware Control**: Charging circuits are controlled by locked firmware, not software
- **Security Design**: Apple intentionally removed charging control to prevent malicious apps

### **📱 What This Means for Your Mac**
- **Intel Macs**: Even with SMC access, battery control keys don't exist on macOS 15.6+
- **Apple Silicon**: No SMC support for battery control at all
- **All Macs**: Charging control is completely locked down by Apple

## 🐛 Troubleshooting

### Common Issues

1. **Menu bar icon not visible**
   - Check System Preferences > Security & Privacy > Accessibility
   - Ensure Battery Limiter is enabled
   - Restart the app if needed

2. **App not starting at login**
   - Check System Preferences > Users & Groups > Login Items
   - Re-run the installation script

3. **App shows limited functionality**
   - This is expected - battery charging control is not possible on modern Macs
   - The app focuses on monitoring and providing battery health insights
   - Check the system compatibility information in the app
   - All Macs have these limitations due to Apple's security restrictions

### Getting Help

- Check the app's built-in help and settings
- Review the console logs for error messages
- Open an issue on GitHub with detailed information

## 🤝 Contributing

Contributions are welcome! Please feel free to submit pull requests or open issues for bugs and feature requests.

See [CONTRIBUTING.md](CONTRIBUTING.md) for development guidelines.

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## ⚠️ Disclaimer

This application modifies system power management settings. While designed to be safe, use at your own risk. The developers are not responsible for any potential damage to your device or data loss.

**Always ensure you have proper backups before installing system-level applications.**
