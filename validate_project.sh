#!/bin/bash

# Battery Limiter Project Validation Script
# This script validates the project structure and identifies potential issues

echo "🔍 Validating Battery Limiter Project Structure..."
echo "=================================================="

# Check if we're on macOS
if [[ "$OSTYPE" != "darwin"* ]]; then
    echo "❌ Error: This script must be run on macOS"
    exit 1
fi

# Check project structure
echo ""
echo "📁 Checking Project Structure..."

# Required files
required_files=(
    "BatteryLimiter.xcodeproj/project.pbxproj"
    "BatteryLimiter/BatteryLimiterApp.swift"
    "BatteryLimiter/ContentView.swift"
    "BatteryLimiter/BatteryMonitor.swift"
    "BatteryLimiter/Info.plist"
    "BatteryLimiter/Assets.xcassets/Contents.json"
    "BatteryLimiter/Assets.xcassets/AppIcon.appiconset/Contents.json"
    "BatteryLimiter/Assets.xcassets/AccentColor.colorset/Contents.json"
    "BatteryLimiter/Preview Content/Preview Assets.xcassets/Contents.json"
)

missing_files=()
for file in "${required_files[@]}"; do
    if [[ -f "$file" ]]; then
        echo "✅ $file"
    else
        echo "❌ $file (MISSING)"
        missing_files+=("$file")
    fi
done

# Check Swift file syntax
echo ""
echo "🔤 Checking Swift File Syntax..."

swift_files=(
    "BatteryLimiter/BatteryLimiterApp.swift"
    "BatteryLimiter/ContentView.swift"
    "BatteryLimiter/BatteryMonitor.swift"
)

# Check if swift command is available (basic syntax check)
if command -v swift &> /dev/null; then
    for file in "${swift_files[@]}"; do
        if [[ -f "$file" ]]; then
            # Basic syntax check
            if swift -frontend -parse "$file" > /dev/null 2>&1; then
                echo "✅ $file (syntax OK)"
            else
                echo "⚠️  $file (syntax check failed)"
            fi
        fi
    done
else
    echo "⚠️  Swift command not available - skipping syntax checks"
fi

# Check Xcode project file
echo ""
echo "📱 Checking Xcode Project File..."

if [[ -f "BatteryLimiter.xcodeproj/project.pbxproj" ]]; then
    # Check if all source files are referenced
    for file in "${swift_files[@]}"; do
        filename=$(basename "$file")
        if grep -q "$filename" "BatteryLimiter.xcodeproj/project.pbxproj"; then
            echo "✅ $filename referenced in project"
        else
            echo "❌ $filename NOT referenced in project"
        fi
    done
else
    echo "❌ Project file not found"
fi

# Check for common issues
echo ""
echo "🔍 Checking for Common Issues..."

# Check for deprecated APIs
if grep -q "NSUserNotification" "BatteryLimiter"/*.swift; then
    echo "⚠️  Found deprecated NSUserNotification usage"
else
    echo "✅ No deprecated NSUserNotification usage found"
fi

# Check for missing imports
if grep -q "IOKit" "BatteryLimiter"/*.swift; then
    echo "✅ IOKit import found"
else
    echo "❌ IOKit import missing"
fi

if grep -q "UserNotifications" "BatteryLimiter"/*.swift; then
    echo "✅ UserNotifications import found"
else
    echo "❌ UserNotifications import missing"
fi

# Check Info.plist
echo ""
echo "📋 Checking Info.plist..."

if [[ -f "BatteryLimiter/Info.plist" ]]; then
    if grep -q "LSUIElement" "BatteryLimiter/Info.plist"; then
        echo "✅ LSUIElement found (menu bar app)"
    else
        echo "❌ LSUIElement missing"
    fi
    
    if grep -q "NSMainNibFile" "BatteryLimiter/Info.plist"; then
        echo "⚠️  NSMainNibFile found (not needed for SwiftUI)"
    else
        echo "✅ NSMainNibFile not found (correct for SwiftUI)"
    fi
else
    echo "❌ Info.plist not found"
fi

# Summary
echo ""
echo "=================================================="
echo "📊 Validation Summary:"

if [[ ${#missing_files[@]} -eq 0 ]]; then
    echo "✅ All required files present"
else
    echo "❌ Missing files: ${#missing_files[@]}"
    for file in "${missing_files[@]}"; do
        echo "   - $file"
    done
fi

echo ""
echo "🚀 Next Steps:"
echo "1. Install Xcode from Mac App Store"
echo "2. Open BatteryLimiter.xcodeproj in Xcode"
echo "3. Press Cmd+R to build and run"
echo ""
echo "💡 If you see any ❌ errors above, they need to be fixed before building"
echo "💡 If you see any ⚠️  warnings, they should be addressed but won't prevent building"
