#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <IOKit/IOKitLib.h>
#include <IOKit/IOKitKeys.h>

// SMC key definitions for battery control
#define SMC_KEY_BCLM "BCLM"  // Battery Charge Level Max
#define SMC_KEY_CH0B "CH0B"  // Charging Control 0B
#define SMC_KEY_CH0C "CH0C"  // Charging Control 0C

typedef struct {
    char key[5];
    uint32_t size;
    uint8_t data[32];
} SMCData;

// SMC connection
static io_connect_t smcConnection = 0;

// Initialize SMC connection
int initSMC() {
    io_service_t service = IOServiceGetMatchingService(kIOMasterPortDefault, 
                                                      IOServiceMatching("AppleSMC"));
    if (!service) {
        printf("ERROR: AppleSMC service not found\n");
        return -1;
    }
    
    kern_return_t result = IOServiceOpen(service, mach_task_self(), 0, &smcConnection);
    IOObjectRelease(service);
    
    if (result != kIOReturnSuccess) {
        printf("ERROR: Failed to open SMC connection: %d\n", result);
        return -1;
    }
    
    printf("✅ SMC connection established\n");
    return 0;
}

// Read SMC key
int readSMC(const char* key, SMCData* data) {
    if (!smcConnection) {
        printf("ERROR: SMC not initialized\n");
        return -1;
    }
    
    memset(data, 0, sizeof(SMCData));
    strncpy(data->key, key, 4);
    data->size = 32;
    
    size_t inputStructSize = sizeof(SMCData);
    size_t outputStructSize = sizeof(SMCData);
    
    kern_return_t result = IOConnectCallStructMethod(smcConnection, 2, 
                                                   data, inputStructSize,
                                                   data, &outputStructSize);
    
    if (result != kIOReturnSuccess) {
        printf("ERROR: Failed to read SMC key %s: %d\n", key, result);
        return -1;
    }
    
    return 0;
}

// Write SMC key
int writeSMC(const char* key, uint32_t value) {
    if (!smcConnection) {
        printf("ERROR: SMC not initialized\n");
        return -1;
    }
    
    SMCData data;
    memset(&data, 0, sizeof(SMCData));
    strncpy(data.key, key, 4);
    data.size = 4;
    
    // Convert value to bytes (little endian)
    data.data[0] = (value >> 24) & 0xFF;
    data.data[1] = (value >> 16) & 0xFF;
    data.data[2] = (value >> 8) & 0xFF;
    data.data[3] = value & 0xFF;
    
    size_t inputStructSize = sizeof(SMCData);
    
    kern_return_t result = IOConnectCallStructMethod(smcConnection, 3, 
                                                   &data, inputStructSize,
                                                   NULL, NULL);
    
    if (result != kIOReturnSuccess) {
        printf("ERROR: Failed to write SMC key %s: %d\n", key, result);
        return -1;
    }
    
    return 0;
}

// List available SMC keys (safe read-only operation)
int listSMCKeys() {
    printf("\n🔍 Scanning for battery-related SMC keys...\n");
    
    const char* batteryKeys[] = {"BCLM", "CH0B", "CH0C", "CH0D", "CH0E", "CH0F"};
    int foundCount = 0;
    
    for (int i = 0; i < 6; i++) {
        SMCData data;
        if (readSMC(batteryKeys[i], &data) == 0) {
            printf("✅ Found: %s (size: %d)\n", batteryKeys[i], data.size);
            foundCount++;
            
            // Show current value
            if (data.size == 4) {
                uint32_t value = (data.data[0] << 24) | (data.data[1] << 16) | 
                                (data.data[2] << 8) | data.data[3];
                printf("   Current value: %u\n", value);
            }
        }
    }
    
    if (foundCount == 0) {
        printf("❌ No battery control SMC keys found\n");
    }
    
    return foundCount;
}

// Test write capability (safe, reversible)
int testWriteCapability(const char* key, uint32_t testValue) {
    printf("\n🧪 Testing write capability for %s...\n", key);
    
    // Read original value
    SMCData originalData;
    if (readSMC(key, &originalData) != 0) {
        printf("❌ Cannot read %s - key may not exist\n", key);
        return -1;
    }
    
    uint32_t originalValue = 0;
    if (originalData.size == 4) {
        originalValue = (originalData.data[0] << 24) | (originalData.data[1] << 16) | 
                       (originalData.data[2] << 8) | originalData.data[3];
        printf("📖 Original value: %u\n", originalValue);
    }
    
    // Attempt write
    printf("✍️  Attempting to write %u to %s...\n", testValue, key);
    if (writeSMC(key, testValue) != 0) {
        printf("❌ Write failed - key may be read-only\n");
        return -1;
    }
    
    // Verify write
    SMCData verifyData;
    if (readSMC(key, &verifyData) != 0) {
        printf("❌ Cannot verify write - key may have been locked\n");
        return -1;
    }
    
    uint32_t verifyValue = 0;
    if (verifyData.size == 4) {
        verifyValue = (verifyData.data[0] << 24) | (verifyData.data[1] << 16) | 
                     (verifyData.data[2] << 8) | verifyData.data[3];
    }
    
    if (verifyValue == testValue) {
        printf("✅ Write successful! Value changed from %u to %u\n", originalValue, verifyValue);
        
        // Restore original value
        printf("🔄 Restoring original value %u...\n", originalValue);
        if (writeSMC(key, originalValue) == 0) {
            printf("✅ Original value restored\n");
        } else {
            printf("⚠️  WARNING: Failed to restore original value!\n");
            printf("   Manual restore may be needed\n");
        }
        
        return 1; // Write capability confirmed
    } else {
        printf("❌ Write verification failed - value is %u (expected %u)\n", verifyValue, testValue);
        return 0; // Write failed
    }
}

// Cleanup
void cleanupSMC() {
    if (smcConnection) {
        IOServiceClose(smcConnection);
        smcConnection = 0;
        printf("🔌 SMC connection closed\n");
    }
}

int main(int argc, char* argv[]) {
    printf("🔋 SMC Battery Control Test Utility (Intel Mac)\n");
    printf("==============================================\n");
    
    if (geteuid() != 0) {
        printf("❌ This utility requires root privileges (sudo)\n");
        printf("   Run: sudo ./smc_test\n");
        return 1;
    }
    
    if (initSMC() != 0) {
        return 1;
    }
    
    // List available keys
    int keyCount = listSMCKeys();
    
    if (keyCount > 0) {
        printf("\n🧪 Testing write capabilities...\n");
        
        // Test BCLM (Battery Charge Level Max) - safest to test first
        if (testWriteCapability("BCLM", 95) > 0) {
            printf("\n🎉 BCLM is writable! Battery charge limiting may be possible.\n");
        }
        
        // Test CH0B (Charging Control) - more aggressive
        if (testWriteCapability("CH0B", 0) > 0) {
            printf("\n🎉 CH0B is writable! Direct charging control may be possible.\n");
        }
        
        // Test CH0C (Charging Control) - alternative method
        if (testWriteCapability("CH0C", 0) > 0) {
            printf("\n🎉 CH0C is writable! Alternative charging control may be possible.\n");
        }
    }
    
    printf("\n📊 Summary:\n");
    printf("   - Found %d battery-related SMC keys\n", keyCount);
    printf("   - Write capability testing completed\n");
    printf("   - Check results above for battery control possibilities\n");
    
    cleanupSMC();
    return 0;
}
