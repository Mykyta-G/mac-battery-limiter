#!/bin/bash

# Build script for SMC Battery Control Test Utility
# Specifically designed for Intel Macs

echo "🔨 Building SMC Battery Control Test Utility..."
echo "=============================================="

# Check if we're on Intel Mac
if [ "$(uname -m)" != "x86_64" ]; then
    echo "❌ This utility is designed for Intel Macs only"
    echo "   Your architecture: $(uname -m)"
    exit 1
fi

# Check if gcc is available
if ! command -v gcc &> /dev/null; then
    echo "❌ gcc compiler not found"
    echo "   Install Xcode Command Line Tools:"
    echo "   xcode-select --install"
    exit 1
fi

# Check if IOKit framework is available
if [ ! -d "/System/Library/Frameworks/IOKit.framework" ]; then
    echo "❌ IOKit framework not found"
    echo "   This suggests a system issue"
    exit 1
fi

echo "✅ System checks passed"
echo "   Architecture: $(uname -m)"
echo "   Compiler: $(gcc --version | head -1)"
echo "   IOKit: Available"
echo ""

# Build the utility
echo "🔨 Compiling smc_test.c..."
gcc -o smc_test smc_test.c -framework IOKit -framework Foundation

if [ $? -eq 0 ]; then
    echo "✅ Compilation successful!"
    echo "   Binary: ./smc_test"
    echo ""
    
    # Make executable
    chmod +x smc_test
    
    # Show file info
    echo "📁 File information:"
    ls -la smc_test
    echo ""
    
    echo "🚀 Ready to test!"
    echo "   Run: sudo ./smc_test"
    echo "   Run: ./verify_charging.sh"
    
else
    echo "❌ Compilation failed!"
    echo "   Check the error messages above"
    exit 1
fi

echo ""
echo "📋 Next steps:"
echo "   1. Run: sudo ./smc_test (to test SMC access)"
echo "   2. Run: ./verify_charging.sh (to monitor charging)"
echo "   3. Check the results in charging_test.log"
echo ""
echo "⚠️  Safety notes:"
echo "   - Always run SMC tests as root (sudo)"
echo "   - The utility automatically restores original values"
echo "   - Monitor your Mac's behavior during testing"
echo "   - Stop immediately if anything seems wrong"
