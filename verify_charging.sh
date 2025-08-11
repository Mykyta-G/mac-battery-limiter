#!/bin/bash

# Battery Charging Verification Script
# Monitors charging behavior when SMC keys are modified

LOG_FILE="charging_test.log"
SMC_TEST="./smc_test"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Log function
log() {
    echo -e "$1" | tee -a "$LOG_FILE"
}

# Get battery info from ioreg
get_battery_info() {
    ioreg -rn AppleSmartBattery | grep -E "(CurrentCapacity|IsCharging|ExternalConnected|Amperage)" | head -4
}

# Get battery info from pmset
get_pmset_battery() {
    pmset -g batt 2>/dev/null
}

# Get system power info
get_power_info() {
    pmset -g | grep -E "(AC Power|Battery Power)"
}

# Monitor charging state
monitor_charging() {
    local duration=$1
    local interval=2
    local count=0
    
    log "${BLUE}🔍 Monitoring charging behavior for ${duration} seconds...${NC}"
    log "${BLUE}   Interval: ${interval}s | Log file: ${LOG_FILE}${NC}"
    log ""
    
    while [ $count -lt $duration ]; do
        timestamp=$(date '+%H:%M:%S')
        
        # Get battery info
        battery_info=$(get_battery_info)
        pmset_info=$(get_pmset_battery)
        power_info=$(get_power_info)
        
        # Extract key values
        current_capacity=$(echo "$battery_info" | grep "CurrentCapacity" | awk '{print $3}' | tr -d '"')
        is_charging=$(echo "$battery_info" | grep "IsCharging" | awk '{print $3}' | tr -d '"')
        external_connected=$(echo "$battery_info" | grep "ExternalConnected" | awk '{print $3}' | tr -d '"')
        amperage=$(echo "$battery_info" | grep "Amperage" | awk '{print $3}' | tr -d '"')
        
        # Format output
        log "${YELLOW}[${timestamp}] Battery Status:${NC}"
        log "   Capacity: ${current_capacity}%"
        log "   Charging: ${is_charging}"
        log "   External: ${external_connected}"
        log "   Amperage: ${amperage} mA"
        
        if [ ! -z "$pmset_info" ]; then
            log "   pmset: $pmset_info"
        fi
        
        if [ ! -z "$power_info" ]; then
            log "   Power: $power_info"
        fi
        
        log ""
        
        sleep $interval
        count=$((count + interval))
    done
}

# Test SMC write and monitor charging
test_smc_charging() {
    local key=$1
    local test_value=$2
    local monitor_duration=30
    
    log "${GREEN}🧪 Testing SMC key: ${key} = ${test_value}${NC}"
    log "${GREEN}==============================================${NC}"
    
    # Baseline monitoring (before change)
    log "${BLUE}📊 Baseline monitoring (before SMC change):${NC}"
    monitor_charging 10
    
    # Attempt SMC write
    log "${YELLOW}✍️  Attempting SMC write: ${key} = ${test_value}${NC}"
    if [ -f "$SMC_TEST" ]; then
        # We'll run the SMC test separately since it needs sudo
        log "${YELLOW}   Run: sudo $SMC_TEST${NC}"
        log "${YELLOW}   Then set ${key} to ${test_value} manually${NC}"
    else
        log "${RED}   SMC test utility not found: $SMC_TEST${NC}"
    fi
    
    # Wait for manual SMC change
    log "${BLUE}⏳ Waiting for SMC change to be applied...${NC}"
    log "${BLUE}   Press Enter when ready to continue monitoring...${NC}"
    read -r
    
    # Monitor charging behavior after change
    log "${BLUE}📊 Monitoring charging behavior after SMC change:${NC}"
    monitor_charging $monitor_duration
    
    # Analysis
    log "${GREEN}📈 Analysis:${NC}"
    log "${GREEN}   - Check if Amperage dropped to near 0${NC}"
    log "${GREEN}   - Check if IsCharging changed to false${NC}"
    log "${GREEN}   - Check if CurrentCapacity stopped increasing${NC}"
    log ""
}

# Main execution
main() {
    # Clear log file
    > "$LOG_FILE"
    
    log "${GREEN}🔋 Battery Charging Verification Script${NC}"
    log "${GREEN}========================================${NC}"
    log "Started: $(date)"
    log "macOS: $(sw_vers -productVersion)"
    log "Architecture: $(uname -m)"
    log ""
    
    # Check if we're running as root
    if [ "$EUID" -eq 0 ]; then
        log "${YELLOW}⚠️  Running as root - be careful with SMC operations${NC}"
    else
        log "${BLUE}ℹ️  Running as user - SMC operations will need sudo${NC}"
    fi
    
    log ""
    
    # Check SMC test utility
    if [ -f "$SMC_TEST" ]; then
        log "${GREEN}✅ SMC test utility found: $SMC_TEST${NC}"
    else
        log "${RED}❌ SMC test utility not found: $SMC_TEST${NC}"
        log "${YELLOW}   Build it first: gcc -o smc_test smc_test.c -framework IOKit${NC}"
    fi
    
    log ""
    
    # Initial battery state
    log "${BLUE}📊 Current battery state:${NC}"
    get_battery_info
    log ""
    get_pmset_battery
    log ""
    
    # Test sequence
    log "${GREEN}🚀 Starting SMC charging tests...${NC}"
    log ""
    
    # Test 1: BCLM (Battery Charge Level Max)
    test_smc_charging "BCLM" "95"
    
    # Test 2: CH0B (Charging Control)
    test_smc_charging "CH0B" "0"
    
    # Test 3: CH0C (Charging Control)
    test_smc_charging "CH0C" "0"
    
    # Final summary
    log "${GREEN}🎯 Test Summary:${NC}"
    log "${GREEN}   - All SMC charging tests completed${NC}"
    log "${GREEN}   - Check log file: $LOG_FILE${NC}"
    log "${GREEN}   - Look for Amperage changes and charging state changes${NC}"
    log ""
    log "${GREEN}✅ Verification script completed at $(date)${NC}"
}

# Run main function
main "$@"
