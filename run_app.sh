#!/bin/bash

echo "🔋 Battery Limiter - Quick Launch"
echo "=================================="

# Check if the app is already built and installed
if [ -d "/Applications/BatteryLimiter.app" ]; then
    echo "✅ Battery Limiter is already installed!"
    echo ""
    echo "🚀 Launching Battery Limiter..."
    
    # Use the launcher script
    ./launch_battery_limiter.sh
    
elif [ -d "./BatteryLimiter-Standalone/BatteryLimiter.app" ]; then
    echo "✅ Found standalone app, installing..."
    echo ""
    
    # Install the standalone app
    cd BatteryLimiter-Standalone
    ./install.sh
    
    # Go back and launch
    cd ..
    ./launch_battery_limiter.sh
    
else
    echo "❌ Battery Limiter not found. Building first..."
    echo ""
    
    # Build the standalone app
    ./build.sh
    
    if [ $? -eq 0 ]; then
        echo ""
        echo "🚀 Now launching Battery Limiter..."
        ./launch_battery_limiter.sh
    else
        echo "❌ Build failed. Please check for errors."
        exit 1
    fi
fi
