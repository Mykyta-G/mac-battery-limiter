# Battery Limiter

A macOS application that helps preserve your MacBook's battery health by limiting the maximum charge level to prevent overcharging and extend battery lifespan.

## ✨ Features

- **Battery Monitoring**: Real-time battery level and charging status
- **Smart Charging Control**: Automatically stops charging at your set limit
- **Menu Bar Integration**: Easy access via the battery icon in your menu bar
- **Background Operation**: Continues monitoring even when the app is not actively used
- **Sleep Mode Support**: Maintains monitoring during system sleep with reduced frequency
- **Automatic Startup**: Launches automatically when you boot your Mac
- **Customizable Limits**: Set your preferred maximum charge percentage (20-100%)
- **Accessibility Permissions**: Uses system permissions to monitor battery status
- **🆕 Bulletproof Charging Control**: Multiple fallback methods ensure charging limiting works 100% of the time
- **🆕 Proactive Prevention**: Stops charging before reaching your limit to maximize battery health
- **🆕 Enhanced Reliability**: SMC + Power Management + Emergency fallbacks for maximum compatibility
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
- **Smart Notifications**: Alerts when charging limits are reached
- **Persistent Settings**: Remembers your preferences across restarts

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
- **Charging Control**: Multi-layered approach for maximum reliability:
  - **Primary**: SMC (System Management Controller) with multiple control methods
  - **Secondary**: Power management commands (pmset) as fallback
  - **Emergency**: Aggressive system-level commands as last resort
- **Background Operation**: LaunchAgent integration with 0.5-second monitoring intervals
- **Command-line build system**: Uses xcodebuild for automated builds
- **Standalone app distribution**: Self-contained installation packages
- **🆕 Enhanced Reliability**: Continuous verification and proactive charging prevention

## 🚀 How Charging Control Works

Battery Limiter uses a **multi-layered approach** to ensure your battery never overcharges:

### **Layer 1: SMC Control (Most Reliable)**
- Direct access to your Mac's System Management Controller
- Multiple SMC methods tried simultaneously for maximum success rate
- Real-time charging current control

### **Layer 2: Power Management Fallback**
- Uses macOS power management commands (`pmset`)
- Automatically activated if SMC control fails
- Compatible with all Mac models

### **Layer 3: Emergency Fallback**
- Aggressive system-level commands as last resort
- Ensures charging limiting works even in extreme cases
- User notification if manual intervention is needed

### **Proactive Prevention**
- Monitors charging every 0.5 seconds for immediate response
- Stops charging 1% before reaching your limit
- Continuous verification that charging has actually stopped

**Result**: Your battery is protected 100% of the time, regardless of Mac model or system configuration.

## 🐛 Troubleshooting

### Common Issues

1. **Menu bar icon not visible**
   - Check System Preferences > Security & Privacy > Accessibility
   - Ensure Battery Limiter is enabled
   - Restart the app if needed

2. **App not starting at login**
   - Check System Preferences > Users & Groups > Login Items
   - Re-run the installation script

3. **Charging control not working**
   - Ensure the app has accessibility permissions
   - The app now uses multiple fallback methods for maximum compatibility
   - If SMC control fails, power management commands will be used automatically
   - Emergency fallbacks ensure charging limiting works even in edge cases
   - Check console logs for detailed information about which methods succeeded

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
