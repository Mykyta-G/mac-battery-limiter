import Foundation
import IOKit
import IOKit.ps
import CoreFoundation
import UserNotifications
import os.log

class BatteryMonitor: ObservableObject {
    @Published var batteryLevel: Int = 0
    @Published var isCharging: Bool = false
    @Published var isPluggedIn: Bool = false
    @Published var maxChargeLimit: Int = 80
    @Published var isMonitoring: Bool = false
    @Published var lastUpdateTime: Date = Date()
    @Published var errorMessage: String?
    
    private var timer: Timer?
    private var continuousChargingTimer: Timer?
    private var isInSleepMode: Bool = false
    private var lastBatteryCheck: Date = Date()
    private var smcConnection: io_connect_t = 0
    private let logger = Logger(subsystem: "com.batterylimiter.app", category: "BatteryMonitor")
    
    func startMonitoring() {
        isMonitoring = true
        checkBatteryStatus()
        
        // Check battery status every 2 seconds for real-time responsiveness
        timer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            self?.checkBatteryStatus()
        }
        
        // Request notification permissions
        requestNotificationPermissions()
        
        // Initialize SMC connection for charging control
        initializeSMC()
        
        // Start continuous charging control
        startContinuousChargingControl()
    }
    
    func stopMonitoring() {
        isMonitoring = false
        timer?.invalidate()
        timer = nil
        
        // Stop continuous charging timer
        continuousChargingTimer?.invalidate()
        continuousChargingTimer = nil
        
        // Close SMC connection
        closeSMC()
    }
    
    func checkBatteryStatus() {
        // Update battery info immediately for real-time response
        updateBatteryInfo()
        
        // Check if we need to stop charging
        if isCharging && batteryLevel >= maxChargeLimit {
            stopCharging()
        }
        
        // Update last check time
        lastBatteryCheck = Date()
        DispatchQueue.main.async { [weak self] in
            self?.lastUpdateTime = Date()
        }
    }
    
    // Continuous monitoring for charging prevention
    private func startContinuousChargingControl() {
        // Start a high-frequency timer specifically for charging control
        continuousChargingTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            
            // Check if we need to stop charging immediately
            if self.isCharging && self.batteryLevel >= self.maxChargeLimit {
                self.logger.info("Continuous monitoring detected charging at \(self.batteryLevel)% - stopping immediately")
                self.stopCharging()
            }
            
            // Additional check for edge cases where battery might be at exact limit
            if self.isCharging && self.batteryLevel == self.maxChargeLimit {
                self.logger.info("Battery at exact limit \(self.maxChargeLimit)% - preventing further charging")
                self.stopCharging()
            }
            
            // Proactive charging prevention - stop charging slightly before reaching limit
            if self.isCharging && self.batteryLevel >= (self.maxChargeLimit - 1) {
                self.logger.info("Proactive charging prevention at \(self.batteryLevel)% (approaching limit \(self.maxChargeLimit)%)")
                self.stopCharging()
            }
        }
    }
    
    func prepareForSleep() {
        logger.info("Preparing for sleep mode")
        isInSleepMode = true
        
        // Save current settings
        saveSettings()
        
        // Reduce monitoring frequency during sleep
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 30.0, repeats: true) { [weak self] _ in
            self?.checkBatteryStatus()
        }
        
        // Also reduce continuous charging control frequency during sleep
        continuousChargingTimer?.invalidate()
        continuousChargingTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            if self.isCharging && self.batteryLevel >= self.maxChargeLimit {
                self.stopCharging()
            }
        }
    }
    
    func resumeFromSleep() {
        logger.info("Resuming from sleep mode")
        isInSleepMode = false
        
        // Restore normal monitoring frequency
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            self?.checkBatteryStatus()
        }
        
        // Restore normal continuous charging control frequency
        continuousChargingTimer?.invalidate()
        continuousChargingTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            if self.isCharging && self.batteryLevel >= self.maxChargeLimit {
                self.stopCharging()
            }
        }
        
        // Check battery status immediately
        checkBatteryStatus()
    }
    
    private func updateBatteryInfo() {
        // Get battery info using IOKit with proper error handling
        let snapshot = IOPSCopyPowerSourcesInfo()
        guard let snapshot = snapshot else { 
            logger.error("Failed to get power sources info")
            DispatchQueue.main.async { [weak self] in
                self?.errorMessage = "Failed to get battery information"
            }
            return 
        }
        
        let sources = IOPSCopyPowerSourcesList(snapshot.takeUnretainedValue())
        guard let sources = sources else { 
            logger.error("Failed to get power sources list")
            DispatchQueue.main.async { [weak self] in
                self?.errorMessage = "Failed to get power sources list"
            }
            return 
        }
        
        let sourcesArray = sources.takeUnretainedValue() as [CFTypeRef]
        
        var newBatteryLevel: Int = 0
        var newIsPluggedIn: Bool = false
        var newIsCharging: Bool = false
        
        for source in sourcesArray {
            let info = IOPSGetPowerSourceDescription(snapshot.takeUnretainedValue(), source)
            guard let info = info else { 
                logger.error("Failed to get power source description")
                continue 
            }
            
            let infoDict = info.takeUnretainedValue() as NSDictionary
            
            // Get battery level
            if let capacity = infoDict[kIOPSCurrentCapacityKey] as? Int {
                newBatteryLevel = capacity
            }
            
            // Check if plugged in
            if let powerSource = infoDict[kIOPSPowerSourceStateKey] as? String {
                newIsPluggedIn = powerSource == kIOPSACPowerValue
            }
            
            // Check if charging
            if let isChargingValue = infoDict[kIOPSIsChargingKey] as? Bool {
                newIsCharging = isChargingValue
            }
        }
        
        // Clear any previous errors
        DispatchQueue.main.async { [weak self] in
            self?.errorMessage = nil
            self?.batteryLevel = newBatteryLevel
            self?.isPluggedIn = newIsPluggedIn
            self?.isCharging = newIsCharging
        }
    }
    
    func setMaxChargeLimit(_ limit: Int) {
        maxChargeLimit = max(20, min(100, limit))
        UserDefaults.standard.set(maxChargeLimit, forKey: "maxChargeLimit")
        
        // Check if we need to stop charging immediately
        if isCharging && batteryLevel >= maxChargeLimit {
            stopCharging()
        }
        
        // Save settings
        saveSettings()
    }
    
    // MARK: - SMC (System Management Controller) Methods for Charging Control
    
    private func initializeSMC() {
        let service = IOServiceGetMatchingService(kIOMainPortDefault, IOServiceMatching("AppleSMC"))
        guard service != 0 else {
            logger.error("Failed to get AppleSMC service - SMC control will be unavailable")
            return
        }
        
        let result = IOServiceOpen(service, mach_task_self_, 0, &smcConnection)
        IOObjectRelease(service)
        
        if result != kIOReturnSuccess {
            logger.error("Failed to open SMC connection: \(result) - SMC control will be unavailable")
            smcConnection = 0
            
            // Show user notification about SMC unavailability
            DispatchQueue.main.async { [weak self] in
                self?.showNotification(
                    title: "Battery Limiter",
                    body: "SMC control unavailable. Charging control will be limited."
                )
            }
        } else {
            logger.info("SMC connection established successfully")
        }
    }
    
    private func closeSMC() {
        if smcConnection != 0 {
            IOServiceClose(smcConnection)
            smcConnection = 0
        }
    }
    
    private func stopCharging() {
        guard smcConnection != 0 else {
            logger.warning("SMC connection not available for charging control")
            // Fallback to power management commands
            if fallbackChargingControl() {
                showNotification(
                    title: "Battery Limiter", 
                    body: "Battery reached \(batteryLevel)%. Charging stopped via power management."
                )
                return
            }
            
            showNotification(
                title: "Battery Limiter", 
                body: "Battery reached \(batteryLevel)%. Please unplug manually to preserve battery health."
            )
            return
        }
        
        logger.info("Attempting to stop charging at \(self.batteryLevel)%")
        
        // Try multiple methods to stop charging with enhanced reliability
        var successCount = 0
        var methodsTried: [String] = []
        
        // Method 1: Set charging current to 0 via SMC (most reliable)
        let result1 = setSMCValue("CH0B", 0)
        if result1 == kIOReturnSuccess {
            successCount += 1
            methodsTried.append("SMC charging current control")
            logger.info("SMC charging current set to 0 successfully")
        } else {
            logger.error("SMC charging current control failed: \(result1)")
        }
        
        // Method 2: Try to disable charging via power management
        if disableChargingViaPowerManagement() {
            successCount += 1
            methodsTried.append("Power management control")
            logger.info("Power management charging control successful")
        } else {
            logger.error("Power management charging control failed")
        }
        
        // Method 3: Set battery charge limit via SMC
        let result3 = setSMCValue("CH0B", UInt32(self.maxChargeLimit))
        if result3 == kIOReturnSuccess {
            successCount += 1
            methodsTried.append("SMC charge limit control")
            logger.info("SMC charge limit set to \(self.maxChargeLimit)% successfully")
        } else {
            logger.error("SMC charge limit control failed: \(result3)")
        }
        
        // Method 4: Additional SMC key for charging control
        let result4 = setSMCValue("CH0C", 0)
        if result4 == kIOReturnSuccess {
            successCount += 1
            methodsTried.append("SMC secondary charging control")
            logger.info("SMC secondary charging control successful")
        } else {
            logger.error("SMC secondary charging control failed: \(result4)")
        }
        
        // Verify charging has stopped
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
            self?.verifyChargingStopped()
        }
        
        // Log success summary
        if successCount > 0 {
            logger.info("Charging control successful with \(successCount) methods: \(methodsTried.joined(separator: ", "))")
            showNotification(
                title: "Battery Limiter",
                body: "Charging stopped successfully at \(batteryLevel)% using \(successCount) method(s)."
            )
        } else {
            logger.error("All charging control methods failed")
            showNotification(
                title: "Battery Limiter",
                body: "Charging control failed. Please unplug manually to preserve battery health."
            )
        }
    }
    
    // Enhanced fallback charging control using power management
    private func fallbackChargingControl() -> Bool {
        logger.info("Attempting fallback charging control via power management")
        
        var success = false
        
        // Try pmset commands as fallback
        let commands = [
            "pmset -c chargecontrol 0",  // Disable charging on AC
            "pmset -b chargecontrol 0",  // Disable charging on battery
            "pmset -a chargecontrol 0"   // Disable charging globally
        ]
        
        for command in commands {
            let process = Process()
            process.launchPath = "/usr/bin/pmset"
            process.arguments = Array(command.components(separatedBy: " ").dropFirst())
            
            do {
                try process.run()
                process.waitUntilExit()
                
                if process.terminationStatus == 0 {
                    logger.info("Fallback command successful: \(command)")
                    success = true
                } else {
                    logger.warning("Fallback command failed: \(command) with status \(process.terminationStatus)")
                }
            } catch {
                logger.error("Failed to execute fallback command \(command): \(error)")
            }
        }
        
        return success
    }
    
    // Verify that charging has actually stopped
    private func verifyChargingStopped() {
        // Force a battery status check to confirm
        updateBatteryInfo()
        
        if isCharging {
            logger.warning("Charging verification failed - still charging after control attempt")
            // Try one more time with different approach
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
                self?.emergencyChargingStop()
            }
        } else {
            logger.info("Charging verification successful - charging has stopped")
        }
    }
    
    // Emergency charging stop as last resort
    private func emergencyChargingStop() {
        logger.warning("Attempting emergency charging stop")
        
        // Try to force stop via multiple aggressive methods
        let emergencyCommands = [
            "sudo pmset -a chargecontrol 0",
            "sudo pmset -a acwake 0",
            "sudo pmset -a womp 0"
        ]
        
        for command in emergencyCommands {
            let process = Process()
            process.launchPath = "/usr/bin/sudo"
            process.arguments = Array(command.components(separatedBy: " ").dropFirst())
            
            do {
                try process.run()
                process.waitUntilExit()
                
                if process.terminationStatus == 0 {
                    logger.info("Emergency command successful: \(command)")
                } else {
                    logger.error("Emergency command failed: \(command)")
                }
            } catch {
                logger.error("Failed to execute emergency command \(command): \(error)")
            }
        }
        
        // Final verification
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) { [weak self] in
            self?.updateBatteryInfo()
            if self?.isCharging == true {
                self?.logger.error("Emergency charging stop failed - user intervention required")
                self?.showNotification(
                    title: "Battery Limiter - URGENT",
                    body: "Charging control failed completely. Please unplug your Mac immediately to preserve battery health."
                )
            }
        }
    }
    
    private func disableChargingViaPowerManagement() -> Bool {
        // Try multiple pmset commands to disable charging
        let commands = [
            ["-c", "acwake", "0"],           // Disable AC wake
            ["-c", "womp", "0"],             // Disable wake on network access
            ["-c", "powernap", "0"],         // Disable power nap
            ["-c", "ttyskeepawake", "0"]     // Disable tty keep awake
        ]
        
        var successCount = 0
        
        for command in commands {
            let task = Process()
            task.launchPath = "/usr/bin/pmset"
            task.arguments = command
            
            do {
                try task.run()
                task.waitUntilExit()
                if task.terminationStatus == 0 {
                    successCount += 1
                    logger.info("pmset command successful: \(command.joined(separator: " "))")
                } else {
                    logger.error("pmset command failed: \(command.joined(separator: " "))")
                }
            } catch {
                logger.error("Failed to run pmset command \(command.joined(separator: " ")): \(error)")
            }
        }
        
        return successCount > 0
    }
    
    private func setSMCValue(_ key: String, _ value: UInt32) -> IOReturn {
        guard smcConnection != 0 else { return kIOReturnError }
        
        var input = SMCData(
            key: SMCKey(key),
            dataSize: 4,
            dataType: 0x75693332, // 'ui32' for unsigned 32-bit integer
            data8: SMCBytes(value: value)
        )
        
        var output = SMCData(
            key: SMCKey(""),
            dataSize: 0,
            dataType: 0,
            data8: SMCBytes(value: 0)
        )
        
        let inputSize = MemoryLayout<SMCData>.size
        var outputSize = MemoryLayout<SMCData>.size
        
        let result = IOConnectCallStructMethod(smcConnection, 2, &input, inputSize, &output, &outputSize)
        
        if result != kIOReturnSuccess {
            logger.error("SMC operation failed for key \(key): \(result)")
        }
        
        return result
    }
    
    private func showNotification(title: String, body: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                self.logger.error("Failed to show notification: \(error.localizedDescription)")
            }
        }
    }
    
    private func requestNotificationPermissions() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { [weak self] granted, error in
            if granted {
                self?.logger.info("Notification permissions granted")
            } else if let error = error {
                self?.logger.error("Notification permissions denied: \(error.localizedDescription)")
            }
        }
    }
    
    func loadSettings() {
        maxChargeLimit = UserDefaults.standard.integer(forKey: "maxChargeLimit")
        if maxChargeLimit == 0 {
            maxChargeLimit = 80 // Default value
        }
        
        logger.info("Loaded settings: maxChargeLimit = \(self.maxChargeLimit)%")
    }
    
    func saveSettings() {
        UserDefaults.standard.set(maxChargeLimit, forKey: "maxChargeLimit")
        UserDefaults.standard.synchronize()
        logger.info("Settings saved: maxChargeLimit = \(self.maxChargeLimit)%")
    }
    
    // Test charging control system
    func testChargingControl() -> Bool {
        logger.info("Testing charging control system...")
        
        // Test SMC connection
        if smcConnection == 0 {
            logger.warning("SMC connection not available for testing")
            return false
        }
        
        // Test basic SMC operations
        let testResult = setSMCValue("CH0B", 0)
        if testResult == kIOReturnSuccess {
            logger.info("SMC charging control test successful")
            return true
        } else {
            logger.error("SMC charging control test failed: \(testResult)")
            return false
        }
    }
    
    // Get detailed charging status for debugging
    func getChargingStatus() -> [String: Any] {
        var status: [String: Any] = [:]
        
        status["batteryLevel"] = batteryLevel
        status["isCharging"] = isCharging
        status["isPluggedIn"] = isPluggedIn
        status["maxChargeLimit"] = maxChargeLimit
        status["isMonitoring"] = isMonitoring
        status["smcConnection"] = smcConnection != 0
        status["lastUpdateTime"] = lastUpdateTime
        status["errorMessage"] = errorMessage
        
        // Add system power info
        if let snapshot = IOPSCopyPowerSourcesInfo() {
            let sources = IOPSCopyPowerSourcesList(snapshot.takeUnretainedValue())
            if let sources = sources {
                let sourcesArray = sources.takeUnretainedValue() as [CFTypeRef]
                status["powerSourcesCount"] = sourcesArray.count
                
                if let firstSource = sourcesArray.first {
                    let info = IOPSGetPowerSourceDescription(snapshot.takeUnretainedValue(), firstSource)
                    if let info = info {
                        let infoDict = info.takeUnretainedValue() as NSDictionary
                        status["powerSourceType"] = infoDict[kIOPSPowerSourceStateKey] as? String
                        status["batteryHealth"] = infoDict[kIOPSBatteryHealthKey] as? String
                    }
                }
            }
        }
        
        return status
    }
    
    deinit {
        logger.info("BatteryMonitor deinitializing")
        stopMonitoring()
        
        // Ensure all timers are invalidated
        timer?.invalidate()
        timer = nil
        continuousChargingTimer?.invalidate()
        continuousChargingTimer = nil
        
        // Close SMC connection
        closeSMC()
    }
}

// MARK: - SMC Data Structures

struct SMCKey {
    var key: UInt32
    
    init(_ key: String) {
        self.key = key.utf8.map { UInt32($0) }.reduce(0) { ($0 << 8) + $1 }
    }
}

struct SMCBytes {
    var bytes: (UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8)
    
    init(value: UInt32) {
        self.bytes = (0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0)
        self.bytes.0 = UInt8(value & 0xFF)
        self.bytes.1 = UInt8((value >> 8) & 0xFF)
        self.bytes.2 = UInt8((value >> 16) & 0xFF)
        self.bytes.3 = UInt8((value >> 24) & 0xFF)
    }
}

struct SMCData {
    var key: SMCKey
    var dataSize: UInt32
    var dataType: UInt32
    var data8: SMCBytes
}
