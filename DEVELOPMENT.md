# 🚀 Development Guide

This guide explains how to run Battery Limiter in development mode for testing and development purposes.

## 🎯 Development vs Production

- **Development Mode**: Run locally for testing, no system installation
- **Production Mode**: Full system installation via `install.sh`

## 🛠️ Quick Start (Development Mode)

### 1. **Run Development Environment**
```bash
./dev_run.sh
```

This script will:
- ✅ Build the app in Debug configuration
- ✅ Run it locally without system installation
- ✅ Provide automatic cleanup when you stop it
- ✅ Show helpful setup instructions

### 2. **Stop Development Environment**
- Press `Ctrl+C` in the terminal
- The script automatically cleans up and stops the app

## 🔧 What Happens in Development Mode

### **Build Process**
- Creates `build/dev/` directory
- Builds Debug version of the app
- No system-wide installation
- No LaunchAgent registration

### **Runtime Behavior**
- App runs exactly like the installed version
- All battery monitoring and charging control works
- Menu bar integration functions normally
- Settings are stored locally (not in system UserDefaults)

### **Cleanup on Exit**
- Automatically kills the running app
- Removes build artifacts
- No system files left behind

## 🚨 Important Development Notes

### **Permissions Required**
Even in development mode, you'll need to grant permissions:
1. **System Preferences > Security & Privacy > General**
   - Click "Allow Anyway" if prompted about BatteryLimiter
2. **System Preferences > Security & Privacy > Accessibility**
   - Add BatteryLimiter and enable it

### **Testing Charging Control**
- The charging control system works identically in development mode
- All fallback methods (SMC, pmset, emergency) are available
- You can test the full reliability features locally

## 🧪 Development Workflow

### **Typical Development Cycle**
1. **Make code changes** in Xcode or your editor
2. **Run development environment**: `./dev_run.sh`
3. **Test functionality** - app runs locally
4. **Stop and cleanup**: Press `Ctrl+C`
5. **Repeat** as needed

### **Benefits of Development Mode**
- ✅ **Fast iteration**: No need to reinstall after changes
- ✅ **Safe testing**: No system integration, easy cleanup
- ✅ **Debug builds**: Full debugging capabilities
- ✅ **Isolated environment**: Won't interfere with system

## 🔍 Troubleshooting Development Mode

### **Build Failures**
- Ensure Xcode command line tools are installed: `xcode-select --install`
- Check that you're in the project root directory
- Verify the Xcode project file exists

### **Permission Issues**
- Follow the permission setup instructions shown by the script
- Check System Preferences > Security & Privacy
- Restart the app if permissions aren't working

### **App Not Starting**
- Check the build output for errors
- Verify the app was built successfully
- Check console logs for any runtime errors

## 📁 File Structure

```
mac-battery-limiter/
├── dev_run.sh          # 🆕 Development runner script
├── DEVELOPMENT.md      # 🆕 This development guide
├── BatteryLimiter/     # Source code
├── build/              # Build artifacts (created by dev_run.sh)
│   └── dev/           # Development build directory
└── ...                 # Other project files
```

## 🎉 Ready to Develop!

Now you can:
- **Test locally** without system installation
- **Iterate quickly** on features and fixes
- **Debug effectively** with full development tools
- **Keep your system clean** during development

Run `./dev_run.sh` to start developing!
