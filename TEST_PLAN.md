# 🔋 SMC Battery Control Test Plan
## Intel MacBook Pro 16,3 (2019-2020) - macOS 15.6

### **🎯 Objective**
Determine if your Intel Mac supports SMC-based battery charging control by testing:
1. **SMC Key Availability** - Which battery control keys exist
2. **Write Capability** - Whether keys can be modified
3. **Charging Behavior** - If changes actually affect charging

### **🔧 Tools Built**
- **`smc_test`** - C utility to read/write SMC keys
- **`verify_charging.sh`** - Bash script to monitor charging behavior
- **`build_smc_test.sh`** - Build script for the utility

### **📋 Test Sequence**

#### **Phase 1: SMC Access Test**
```bash
# Test SMC connection and key discovery
sudo ./smc_test
```
**Expected Results:**
- ✅ SMC connection established
- 🔍 Found: BCLM, CH0B, CH0C (or similar)
- 🧪 Write capability testing completed

#### **Phase 2: Charging Behavior Monitoring**
```bash
# Monitor charging behavior during SMC changes
./verify_charging.sh
```
**What to Look For:**
- **Amperage drops to ~0 mA** when charging should stop
- **IsCharging changes to false**
- **CurrentCapacity stops increasing**

#### **Phase 3: Manual Verification**
```bash
# Real-time monitoring during SMC changes
watch -n 2 'ioreg -rn AppleSmartBattery | grep -E "(CurrentCapacity|IsCharging|Amperage)"'
```

### **🔍 Key Metrics to Monitor**

#### **Battery State (ioreg)**
- `CurrentCapacity` - Battery percentage
- `IsCharging` - True/False charging state
- `ExternalConnected` - AC adapter connected
- `Amperage` - **CRITICAL**: Charging current in mA

#### **Power Management (pmset)**
- `pmset -g batt` - Battery status
- `pmset -g` - Overall power state

### **⚠️ Safety Protocols**

#### **Before Testing**
1. **Backup SMC values** - Utility does this automatically
2. **Monitor system** - Watch for unusual behavior
3. **Have recovery plan** - Know how to restore defaults

#### **During Testing**
1. **Start with BCLM** - Safest key to test
2. **Small changes first** - Test with 95% before 0%
3. **Monitor continuously** - Watch charging behavior
4. **Stop if unstable** - Don't push unstable systems

#### **After Testing**
1. **Verify restoration** - Check original values restored
2. **Monitor stability** - Ensure system remains stable
3. **Document results** - Record what worked/didn't work

### **🎯 Success Criteria**

#### **Level 1: Basic SMC Access**
- ✅ SMC connection established
- ✅ Battery keys readable
- ✅ Keys show reasonable values

#### **Level 2: Write Capability**
- ✅ SMC keys can be modified
- ✅ Changes persist (don't revert immediately)
- ✅ Original values can be restored

#### **Level 3: Charging Control**
- ✅ Amperage drops when limit reached
- ✅ Charging state changes appropriately
- ✅ Battery level stops increasing
- ✅ System remains stable

### **📊 Expected Outcomes**

#### **Best Case Scenario**
- **BCLM writable** → Set charge limit to 95%
- **CH0B/CH0C writable** → Direct charging control
- **Charging stops** at set limits
- **System stable** throughout

#### **Partial Success**
- **Keys readable** but not writable
- **Limited control** via some keys
- **Charging behavior** partially affected

#### **No Success**
- **Keys don't exist** on your system
- **Keys read-only** (firmware locked)
- **No charging effect** from changes

### **🚨 Troubleshooting**

#### **Common Issues**
1. **"SMC service not found"** → AppleSMC.kext not loaded
2. **"Failed to open SMC"** → Permission/entitlement issue
3. **"Write failed"** → Key is read-only or locked
4. **"Value reverts"** → Firmware overriding changes

#### **Recovery Steps**
1. **Restart SMC** - Shutdown, wait 10s, restart
2. **Reset NVRAM** - Cmd+Option+P+R during boot
3. **Safe Mode** - Boot in safe mode if needed
4. **System Restore** - Last resort if system unstable

### **📝 Test Log Template**

```
Date: ___________
macOS: 15.6
Architecture: x86_64
Tester: ___________

Phase 1 - SMC Access:
- Connection: [✅/❌]
- Keys Found: [List]
- Write Capable: [List]

Phase 2 - Charging Control:
- BCLM Test: [✅/❌] - Notes:
- CH0B Test: [✅/❌] - Notes:
- CH0C Test: [✅/❌] - Notes:

Phase 3 - Behavior Verification:
- Amperage Changes: [✅/❌] - Notes:
- Charging State: [✅/❌] - Notes:
- System Stability: [✅/❌] - Notes:

Overall Result: [Success/Partial/None]
Recommendation: [Use/Don't Use/Further Testing]
```

### **🎯 Next Steps After Testing**

#### **If Successful**
1. **Integrate into BatteryLimiter app**
2. **Test with different charge limits**
3. **Verify persistence across reboots**
4. **Monitor long-term stability**

#### **If Partial Success**
1. **Identify which keys work**
2. **Test alternative approaches**
3. **Combine with pmset methods**
4. **Document limitations**

#### **If No Success**
1. **Confirm SMC is locked down**
2. **Focus on monitoring only**
3. **Use built-in battery health features**
4. **Consider hardware alternatives**

---

**Ready to test?** Run `sudo ./smc_test` to begin!
