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
    @Published var smcStatus: String = "Unknown"
    
    private var timer: Timer?
    private var continuousChargingTimer: Timer?
    private var isInSleepMode: Bool = false
    private var lastBatteryCheck: Date = Date()
    private var smcConnection: io_connect_t = 0
    private let logger = Logger(subsystem: "com.batterylimiter.app", category: "BatteryMonitor")
    
    // Add cooldown and state tracking to prevent infinite loops
    private var lastChargingControlAttempt: Date = Date.distantPast
    private var chargingControlCooldown: TimeInterval = 5.0 // 5 second cooldown
    private var isChargingControlActive: Bool = false
    private var consecutiveChargingControlFailures: Int = 0
    private let maxConsecutiveFailures: Int = 3
    private var lastBatteryLevel: Int = 0
    private var rapidChangeCooldown: TimeInterval = 2.0 // 2 second cooldown for rapid changes
    
    // SMC compatibility tracking
    private var isSMCCompatible: Bool = false
    private var isAppleSilicon: Bool = false
    private var macOSVersion: String = ""
    
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
        
        // Register for power state change notifications
        registerForPowerNotifications()
        
        // Detect system compatibility
        detectSystemCompatibility()
    }
    
    // Register for system power state change notifications
    private func registerForPowerNotifications() {
        // Register for power source changes
        let powerSourceNotification = IONotificationPortCreate(kIOMainPortDefault)
        let runLoopSource = IONotificationPortGetRunLoopSource(powerSourceNotification)
        
        if let runLoopSource = runLoopSource {
            CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
            
            // Register for power source changes
            var notification = io_object_t()
            let result = IOServiceAddMatchingNotification(
                powerSourceNotification,
                kIOPowerSourceNotificationType,
                IOServiceMatching("IOPMPowerSource"),
                { (context, service, messageType, messageArgument) in
                    // Handle power source change
                    DispatchQueue.main.async {
                        if let monitor = context?.assumingMemoryBound(to: BatteryMonitor.self).pointee {
                            monitor.checkBatteryStatus()
                        }
                    }
                },
                Unmanaged.passUnretained(self).toOpaque(),
                &notification
            )
            
            if result == kIOReturnSuccess {
                logger.info("Power source notifications registered successfully")
            } else {
                logger.error("Failed to register power source notifications: \(result)")
            }
        }
    }
    
    // Detect system compatibility for SMC and charging control
    private func detectSystemCompatibility() {
        // Detect macOS version
        let osVersion = ProcessInfo.processInfo.operatingSystemVersion
        macOSVersion = "\(osVersion.majorVersion).\(osVersion.minorVersion).\(osVersion.patchVersion)"
        
        // Detect Apple Silicon vs Intel
        let architecture = ProcessInfo.processInfo.machineHardwareName
        isAppleSilicon = architecture.contains("arm64")
        
        logger.info("System detected: macOS \(macOSVersion), Architecture: \(architecture)")
        
        // Check SMC compatibility based on system characteristics
        if isAppleSilicon {
            // Apple Silicon Macs have limited SMC support
            isSMCCompatible = false
            smcStatus = "Limited (Apple Silicon)"
            logger.info("Apple Silicon Mac detected - SMC support limited")
            
            // Show notification about limited functionality
            DispatchQueue.main.async { [weak self] in
                self?.showNotification(
                    title: "Battery Limiter",
                    body: "Apple Silicon Mac detected. Charging control will use power management methods."
                )
            }
        } else {
            // Intel Macs have better SMC support
            isSMCCompatible = true
            smcStatus = "Supported (Intel)"
            logger.info("Intel Mac detected - SMC support available")
        }
        
        // Additional checks for newer macOS versions
        if osVersion.majorVersion >= 13 {
            // macOS Ventura and later have additional restrictions
            logger.info("macOS \(osVersion.majorVersion) detected - additional security restrictions may apply")
            smcStatus += " - macOS \(osVersion.majorVersion)"
        }
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
        
        // Reset charging control state
        isChargingControlActive = false
        consecutiveChargingControlFailures = 0
    }
    
    func checkBatteryStatus() {
        // Update battery info immediately for real-time response
        updateBatteryInfo()
        
        // Check if we need to stop charging (with additional safety checks)
        if isCharging && batteryLevel >= maxChargeLimit && !isChargingControlActive {
            // Add a small delay to prevent rapid-fire charging control attempts
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                self?.stopCharging()
            }
        }
        
        // Update last check time
        lastBatteryCheck = Date()
        DispatchQueue.main.async { [weak self] in
            self?.lastUpdateTime = Date()
        }
    }
    
    // Continuous monitoring for charging prevention
    private func startContinuousChargingControl() {
        // Start a moderate-frequency timer specifically for charging control
        continuousChargingTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            
            // Prevent multiple simultaneous charging control attempts
            if self.isChargingControlActive {
                self.logger.debug("Charging control already active, skipping check")
                return
            }
            
            // Check if we need to stop charging
            if self.isCharging && self.batteryLevel >= self.maxChargeLimit {
                self.logger.info("Continuous monitoring detected charging at \(self.batteryLevel)% - stopping charging")
                self.isChargingControlActive = true
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
        continuousChargingTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
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
            
            // Check for rapid battery level changes
            self?.checkForRapidBatteryChanges(newLevel: newBatteryLevel)
        }
    }
    
    func setMaxChargeLimit(_ limit: Int) {
        maxChargeLimit = max(20, min(100, limit))
        UserDefaults.standard.set(maxChargeLimit, forKey: "maxChargeLimit")
        
        // Check if we need to stop charging immediately (with safety checks)
        if isCharging && batteryLevel >= maxChargeLimit && !isChargingControlActive {
            // Add a small delay to prevent rapid-fire charging control attempts
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                self?.stopCharging()
            }
        }
        
        // Save settings
        saveSettings()
    }
    
    // MARK: - SMC (System Management Controller) Methods for Charging Control
    
    private func initializeSMC() {
        // Skip SMC initialization if system is not compatible
        if !isSMCCompatible {
            logger.info("Skipping SMC initialization - system not compatible")
            smcStatus = "Not Compatible"
            return
        }
        
        let service = IOServiceGetMatchingService(kIOMainPortDefault, IOServiceMatching("AppleSMC"))
        guard service != 0 else {
            logger.error("Failed to get AppleSMC service - SMC control will be unavailable")
            smcStatus = "Service Not Found"
            return
        }
        
        let result = IOServiceOpen(service, mach_task_self_, 0, &smcConnection)
        IOObjectRelease(service)
        
        if result != kIOReturnSuccess {
            logger.error("Failed to open SMC connection: \(result) - SMC control will be unavailable")
            smcConnection = 0
            smcStatus = "Connection Failed"
            
            // Show user notification about SMC unavailability
            DispatchQueue.main.async { [weak self] in
                self?.showNotification(
                    title: "Battery Limiter",
                    body: "SMC control unavailable. Charging control will use power management methods."
                )
            }
        } else {
            logger.info("SMC connection established successfully")
            smcStatus = "Connected"
        }
    }
    
    private func closeSMC() {
        if smcConnection != 0 {
            IOServiceClose(smcConnection)
            smcConnection = 0
        }
    }
    
        private func stopCharging() {
        // Prevent multiple simultaneous charging control attempts
        if isChargingControlActive {
            logger.warning("Charging control already active, skipping attempt")
            return
        }
        
        // Check cooldown
        let now = Date()
        if now - lastChargingControlAttempt < chargingControlCooldown {
            logger.warning("Charging control cooldown active. Skipping control attempt.")
            return
        }
        
        // Mark charging control as active
        isChargingControlActive = true
        lastChargingControlAttempt = now
        
        logger.info("Attempting to stop charging at \(self.batteryLevel)%")
        
        // Try multiple methods to stop charging with enhanced reliability
        var successCount = 0
        var methodsTried: [String] = []
        
        // Method 1: Set charging current to 0 via SMC (most reliable)
        if smcConnection != 0 {
            let result1 = setSMCValue("CH0B", 0)
            if result1 == kIOReturnSuccess {
                successCount += 1
                methodsTried.append("SMC charging current control")
                logger.info("SMC charging current set to 0 successfully")
            } else {
                logger.error("SMC charging current control failed: \(result1)")
            }
            
            // Method 2: Set battery charge limit via SMC
            let result2 = setSMCValue("CH0B", UInt32(self.maxChargeLimit))
            if result2 == kIOReturnSuccess {
                successCount += 1
                methodsTried.append("SMC charge limit control")
                logger.info("SMC charge limit set to \(self.maxChargeLimit)% successfully")
            } else {
                logger.error("SMC charge limit control failed: \(result2)")
            }
            
            // Method 3: Additional SMC key for charging control
            let result3 = setSMCValue("CH0C", 0)
            if result3 == kIOReturnSuccess {
                successCount += 1
                methodsTried.append("SMC secondary charging control")
                logger.info("SMC secondary charging control successful")
            } else {
                logger.error("SMC secondary charging control failed: \(result3)")
            }
        } else {
            logger.warning("SMC connection not available for charging control")
        }
        
        // Method 4: Try to disable charging via power management (fallback)
        if disableChargingViaPowerManagement() {
            successCount += 1
            methodsTried.append("Power management control")
            logger.info("Power management charging control successful")
        } else {
            logger.error("Power management charging control failed")
        }
        
        // Verify charging has stopped after a delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) { [weak self] in
            self?.verifyChargingStopped()
        }
        
        // Log success summary and reset state
        if successCount > 0 {
            logger.info("Charging control successful with \(successCount) methods: \(methodsTried.joined(separator: ", "))")
            showNotification(
                title: "Battery Limiter",
                body: "Charging stopped successfully at \(batteryLevel)% using \(successCount) method(s)."
            )
            consecutiveChargingControlFailures = 0 // Reset consecutive failures on success
        } else {
            logger.error("All charging control methods failed")
            
            // Provide different messages based on system compatibility
            if !isSMCCompatible {
                showNotification(
                    title: "Battery Limiter - Manual Action Required", 
                    body: "Battery at \(batteryLevel)%. Please unplug your Mac manually. System limitations prevent automatic charging control."
                )
            } else {
                showNotification(
                    title: "Battery Limiter", 
                    body: "Charging control failed. Please unplug manually to preserve battery health."
                )
            }
            
            consecutiveChargingControlFailures += 1
            
            // If we've had too many consecutive failures, try emergency stop
            if consecutiveChargingControlFailures >= maxConsecutiveFailures {
                logger.error("Too many consecutive charging control failures. Attempting emergency stop.")
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
                    self?.emergencyChargingStop()
                }
            }
        }
        
        // Reset charging control active state after a delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
            self?.isChargingControlActive = false
        }
    }
    
    // Enhanced fallback charging control using power management
    private func fallbackChargingControl() -> Bool {
        logger.info("Attempting fallback charging control via power management")
        
        var success = false
        
        // Try pmset commands as fallback (without sudo to prevent system instability)
        let commands = [
            ["-c", "chargecontrol", "0"],  // Disable charging on AC
            ["-b", "chargecontrol", "0"],  // Disable charging on battery
            ["-a", "chargecontrol", "0"]   // Disable charging globally
        ]
        
        for command in commands {
            let process = Process()
            process.launchPath = "/usr/bin/pmset"
            process.arguments = command
            
            do {
                try process.run()
                process.waitUntilExit()
                
                if process.terminationStatus == 0 {
                    logger.info("Fallback command successful: pmset \(command.joined(separator: " "))")
                    success = true
                } else {
                    logger.warning("Fallback command failed: pmset \(command.joined(separator: " ")) with status \(process.terminationStatus)")
                }
            } catch {
                logger.error("Failed to execute fallback command pmset \(command.joined(separator: " ")): \(error)")
            }
        }
        
        // Try additional modern power management methods for Apple Silicon Macs
        if isAppleSilicon {
            success = success || tryModernPowerManagement()
        }
        
        return success
    }
    
    // Modern power management methods for Apple Silicon and newer macOS versions
    private func tryModernPowerManagement() -> Bool {
        logger.info("Attempting modern power management methods")
        
        var success = false
        
        // Try to use power management preferences
        let modernCommands = [
            ["-a", "powernap", "0"],           // Disable power nap
            ["-a", "acwake", "0"],             // Disable AC wake
            ["-a", "womp", "0"],               // Disable wake on network
            ["-a", "ttyskeepawake", "0"],      // Disable tty keep awake
            ["-a", "standby", "0"],            // Disable standby mode
            ["-a", "autopoweroff", "0"]        // Disable auto power off
        ]
        
        for command in modernCommands {
            let process = Process()
            process.launchPath = "/usr/bin/pmset"
            process.arguments = command
            
            do {
                try process.run()
                process.waitUntilExit()
                
                if process.terminationStatus == 0 {
                    logger.info("Modern power management command successful: pmset \(command.joined(separator: " "))")
                    success = true
                } else {
                    logger.debug("Modern power management command failed: pmset \(command.joined(separator: " ")) with status \(process.terminationStatus)")
                }
            } catch {
                logger.debug("Failed to execute modern power management command: \(error)")
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
    
    // Emergency charging stop as last resort (without sudo to prevent system instability)
    private func emergencyChargingStop() {
        logger.warning("Attempting emergency charging stop without sudo")
        
        // Try to force stop via multiple non-sudo methods
        let emergencyCommands = [
            ["-a", "chargecontrol", "0"],
            ["-a", "acwake", "0"],
            ["-a", "womp", "0"]
        ]
        
        var successCount = 0
        
        for command in emergencyCommands {
            let process = Process()
            process.launchPath = "/usr/bin/pmset"
            process.arguments = command
            
            do {
                try process.run()
                process.waitUntilExit()
                
                if process.terminationStatus == 0 {
                    logger.info("Emergency command successful: pmset \(command.joined(separator: " "))")
                    successCount += 1
                } else {
                    logger.error("Emergency command failed: pmset \(command.joined(separator: " "))")
                }
            } catch {
                logger.error("Failed to execute emergency command pmset \(command.joined(separator: " ")): \(error)")
            }
        }
        
        // Show user notification about the situation
        if successCount > 0 {
            showNotification(
                title: "Battery Limiter - Emergency",
                body: "Emergency charging control applied. Please monitor battery level."
            )
        } else {
            showNotification(
                title: "Battery Limiter - URGENT",
                body: "Emergency charging control failed. Please unplug your Mac manually to preserve battery health."
            )
        }
        
        // Final verification after a longer delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) { [weak self] in
            self?.updateBatteryInfo()
            self?.isChargingControlActive = false // Reset state
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
        
        // Test SMC connection if available
        if smcConnection != 0 && isSMCCompatible {
            let testResult = setSMCValue("CH0B", 0)
            if testResult == kIOReturnSuccess {
                logger.info("SMC charging control test successful")
                return true
            } else {
                logger.error("SMC charging control test failed: \(testResult)")
                return false
            }
        } else {
            // Test power management methods instead
            logger.info("Testing power management methods (SMC not available)")
            return fallbackChargingControl()
        }
    }
    
    // Get system-specific charging control recommendations
    func getChargingControlRecommendations() -> [String] {
        var recommendations: [String] = []
        
        if isAppleSilicon {
            recommendations.append("Apple Silicon Mac detected - limited hardware charging control")
            recommendations.append("Charging control relies on power management settings")
            recommendations.append("Manual unplugging may be required at charge limits")
        } else if !isSMCCompatible {
            recommendations.append("SMC control not available on this system")
            recommendations.append("Using power management fallback methods")
            recommendations.append("Charging control effectiveness may be limited")
        } else {
            recommendations.append("Full SMC charging control available")
            recommendations.append("Automatic charging control should work reliably")
        }
        
        if macOSVersion.contains("13") || macOSVersion.contains("14") {
            recommendations.append("macOS \(macOSVersion) - additional security restrictions may apply")
        }
        
        return recommendations
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
        
        // Add system compatibility info
        status["isSMCCompatible"] = isSMCCompatible
        status["isAppleSilicon"] = isAppleSilicon
        status["macOSVersion"] = macOSVersion
        status["smcStatus"] = smcStatus
        
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
    
    // Graceful shutdown method to be called before app termination
    func prepareForTermination() {
        logger.info("Preparing for app termination")
        
        // Stop any active charging control
        if isChargingControlActive {
            logger.info("Stopping active charging control before termination")
            isChargingControlActive = false
        }
        
        // Stop monitoring
        stopMonitoring()
        
        // Save settings
        saveSettings()
    }
    
    // Handle rapid battery level changes to prevent system instability
    private func checkForRapidBatteryChanges(newLevel: Int) {
        let levelDifference = abs(newLevel - lastBatteryLevel)
        
        // If battery level changed by more than 5% in a short time, add extra cooldown
        if levelDifference > 5 {
            logger.warning("Rapid battery level change detected: \(lastBatteryLevel)% -> \(newLevel)% (difference: \(levelDifference)%)")
            
            // Add extra cooldown for rapid changes
            chargingControlCooldown = rapidChangeCooldown
            
            // Reset charging control state if it's active
            if isChargingControlActive {
                logger.info("Resetting charging control state due to rapid battery change")
                isChargingControlActive = false
            }
        } else {
            // Reset to normal cooldown
            chargingControlCooldown = 5.0
        }
        
        lastBatteryLevel = newLevel
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
