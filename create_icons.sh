#!/bin/bash

# Create placeholder app icons for Battery Limiter
# This script creates simple colored squares as placeholder icons

ICON_DIR="BatteryLimiter/Assets.xcassets/AppIcon.appiconset"

# Check if sips is available (built into macOS)
if command -v sips &> /dev/null; then
    echo "Using sips to create placeholder icons..."
    
    # Create a simple colored square for each size
    # 16x16
    sips -s format png -z 16 16 --setProperty format png --setProperty formatOptions default "$ICON_DIR/icon_16x16.png" 2>/dev/null || echo "Could not create 16x16 icon"
    
    # 32x32
    sips -s format png -z 32 32 --setProperty format png --setProperty formatOptions default "$ICON_DIR/icon_32x32.png" 2>/dev/null || echo "Could not create 32x32 icon"
    
    # 128x128
    sips -s format png -z 128 128 --setProperty format png --setProperty formatOptions default "$ICON_DIR/icon_128x128.png" 2>/dev/null || echo "Could not create 128x128 icon"
    
    # 256x256
    sips -s format png -z 256 256 --setProperty format png --setProperty formatOptions default "$ICON_DIR/icon_256x256.png" 2>/dev/null || echo "Could not create 256x256 icon"
    
    echo "Placeholder icons created using sips"
else
    echo "sips not available. Please create icon files manually:"
    echo "- icon_16x16.png"
    echo "- icon_32x32.png" 
    echo "- icon_128x128.png"
    echo "- icon_256x256.png"
    echo "Place them in: $ICON_DIR"
fi
