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
    "build.sh"
    "run_app.sh"
    "launch_battery_limiter.sh"
    "validate_project.sh"
    "README.md"
    "CONTRIBUTING.md"
    "LICENSE"
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
if grep -q "import os.log" "BatteryLimiter"/*.swift; then
    echo "✅ os.log import found (proper logging)"
else
    echo "❌ Missing os.log import (using print statements)"
fi

# Check for print statements (should be removed in production)
print_statements=$(grep -r "print(" "BatteryLimiter"/*.swift | wc -l)
if [[ $print_statements -eq 0 ]]; then
    echo "✅ No print statements found (good for production)"
else
    echo "⚠️  Found $print_statements print statements (should use Logger instead)"
fi

# Check for memory leaks
if grep -q "weak self" "BatteryLimiter"/*.swift; then
    echo "✅ Weak self references found (prevents memory leaks)"
else
    echo "⚠️  No weak self references found (potential memory leaks)"
fi

# Check for proper deinit
if grep -q "deinit" "BatteryLimiter"/*.swift; then
    echo "✅ deinit blocks found (proper cleanup)"
else
    echo "⚠️  No deinit blocks found (potential resource leaks)"
fi

# Check for force operations
if grep -q "force" "BatteryLimiter"/*.swift; then
    echo "⚠️  Force operations found (potential crashes)"
else
    echo "✅ No force operations found (safe code)"
fi

# Check for proper error handling
if grep -q "guard.*else" "BatteryLimiter"/*.swift; then
    echo "✅ Guard statements found (proper error handling)"
else
    echo "⚠️  No guard statements found (poor error handling)"
fi

# Check for sudo usage in scripts
echo ""
echo "🔒 Checking Script Security..."

scripts=("build.sh" "run_app.sh" "launch_battery_limiter.sh" "BatteryLimiter-Standalone/install.sh" "BatteryLimiter-Standalone/uninstall.sh")

for script in "${scripts[@]}"; do
    if [[ -f "$script" ]]; then
        sudo_count=$(grep -c "sudo" "$script" 2>/dev/null || echo "0")
        if [[ $sudo_count -eq 0 ]]; then
            echo "✅ $script (no sudo usage - secure)"
        else
            echo "⚠️  $script ($sudo_count sudo commands - security concern)"
        fi
    fi
done

# Check for proper validation in scripts
echo ""
echo "✅ Checking Script Validation..."

for script in "${scripts[@]}"; do
    if [[ -f "$script" ]]; then
        if grep -q "OSTYPE.*darwin" "$script"; then
            echo "✅ $script (macOS validation)"
        else
            echo "⚠️  $script (no macOS validation)"
        fi
    fi
done

# Check for proper permissions handling
echo ""
echo "🔐 Checking Permissions Handling..."

for script in "${scripts[@]}"; do
    if [[ -f "$script" ]]; then
        if grep -q "chmod\|chown" "$script"; then
            echo "✅ $script (proper permissions handling)"
        else
            echo "⚠️  $script (no permissions handling)"
        fi
    fi
done

# Check for proper error handling in scripts
echo ""
echo "🚨 Checking Script Error Handling..."

for script in "${scripts[@]}"; do
    if [[ -f "$script" ]]; then
        if grep -q "exit 1" "$script"; then
            echo "✅ $script (proper error handling)"
        else
            echo "⚠️  $script (no error handling)"
        fi
    fi
done

# Check for proper cleanup in scripts
echo ""
echo "🧹 Checking Script Cleanup..."

for script in "${scripts[@]}"; do
    if [[ -f "$script" ]]; then
        if grep -q "rm -rf\|cleanup\|clean" "$script"; then
            echo "✅ $script (cleanup operations)"
        else
            echo "⚠️  $script (no cleanup operations)"
        fi
    fi
done

# Check for proper documentation
echo ""
echo "📚 Checking Documentation..."

if [[ -f "README.md" ]]; then
    if grep -q "Uninstallation\|uninstall" "README.md"; then
        echo "✅ README.md (uninstall instructions)"
    else
        echo "⚠️  README.md (missing uninstall instructions)"
    fi
    
    if grep -q "Troubleshooting\|troubleshoot" "README.md"; then
        echo "✅ README.md (troubleshooting section)"
    else
        echo "⚠️  README.md (missing troubleshooting section)"
    fi
fi

# Check for proper license
if [[ -f "LICENSE" ]]; then
    echo "✅ LICENSE file found"
else
    echo "❌ LICENSE file missing"
fi

# Check for contributing guidelines
if [[ -f "CONTRIBUTING.md" ]]; then
    echo "✅ CONTRIBUTING.md found"
else
    echo "⚠️  CONTRIBUTING.md missing"
fi

# Summary
echo ""
echo "=================================================="
echo "📊 Validation Summary:"

if [[ ${#missing_files[@]} -eq 0 ]]; then
    echo "✅ All required files present"
else
    echo "❌ Missing files: ${missing_files[*]}"
fi

echo ""
echo "💡 If you see any ❌ errors above, they need to be fixed before building"
echo "💡 ⚠️  warnings indicate areas that could be improved"
echo "💡 ✅ items are properly configured"

# Exit with error if critical files are missing
if [[ ${#missing_files[@]} -gt 0 ]]; then
    exit 1
fi

echo ""
echo "🎉 Project validation complete! Your project looks good to go."
