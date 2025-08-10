import Foundation
import IOKit
import IOKit.ps
import CoreFoundation
import UserNotifications

class BatteryMonitor: ObservableObject {
    @Published var batteryLevel: Int = 0
    @Published var isCharging: Bool = false
    @Published var isPluggedIn: Bool = false
    @Published var maxChargeLimit: Int = 80
    @Published var isMonitoring: Bool = false
    @Published var lastUpdateTime: Date = Date()
    
    private var timer: Timer?
    private var isInSleepMode: Bool = false
    private var lastBatteryCheck: Date = Date()
    private var smcConnection: io_connect_t = 0
    
    func startMonitoring() {
        isMonitoring = true
        checkBatteryStatus()
        
        // Check battery status every 2 seconds for real-time responsiveness
        timer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { _ in
            self.checkBatteryStatus()
        }
        
        // Load saved settings
        loadSettings()
        
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
        DispatchQueue.main.async {
            self.lastUpdateTime = Date()
        }
        
        // Log battery status for debugging
        print("Battery: \(batteryLevel)%, Charging: \(isCharging), Plugged: \(isPluggedIn)")
    }
    
    // Continuous monitoring for charging prevention
    private func startContinuousChargingControl() {
        // Start a high-frequency timer specifically for charging control
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            if self.isCharging && self.batteryLevel >= self.maxChargeLimit {
                self.stopCharging()
            }
        }
    }
    
    func prepareForSleep() {
        print("Preparing for sleep mode...")
        isInSleepMode = true
        
        // Save current settings
        saveSettings()
        
        // Reduce monitoring frequency during sleep
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 30.0, repeats: true) { _ in
            self.checkBatteryStatus()
        }
        
        print("Battery Limiter is now in sleep mode with reduced monitoring")
    }
    
    func resumeFromSleep() {
        print("Resuming from sleep mode...")
        isInSleepMode = false
        
        // Restore normal monitoring frequency
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { _ in
            self.checkBatteryStatus()
        }
        
        // Check battery status immediately
        checkBatteryStatus()
        
        print("Battery Limiter resumed normal monitoring")
    }
    
    private func updateBatteryInfo() {
        // Get battery info using IOKit with proper error handling
        let snapshot = IOPSCopyPowerSourcesInfo()
        guard snapshot != nil else { 
            print("Failed to get power sources info")
            return 
        }
        
        let sources = IOPSCopyPowerSourcesList(snapshot!.takeUnretainedValue())
        guard sources != nil else { 
            print("Failed to get power sources list")
            return 
        }
        
        let sourcesArray = sources!.takeUnretainedValue() as [CFTypeRef]
        
        for source in sourcesArray {
            let info = IOPSGetPowerSourceDescription(snapshot!.takeUnretainedValue(), source)
            guard info != nil else { 
                print("Failed to get power source description")
                continue 
            }
            
            let infoDict = info!.takeUnretainedValue() as NSDictionary
            
            // Get battery level
            if let capacity = infoDict[kIOPSCurrentCapacityKey] as? Int {
                DispatchQueue.main.async {
                    self.batteryLevel = capacity
                }
            }
            
            // Check if plugged in
            if let powerSource = infoDict[kIOPSPowerSourceStateKey] as? String {
                DispatchQueue.main.async {
                    self.isPluggedIn = powerSource == kIOPSACPowerValue
                }
            }
            
            // Check if charging
            if let isChargingValue = infoDict[kIOPSIsChargingKey] as? Bool {
                DispatchQueue.main.async {
                    self.isCharging = isChargingValue
                }
            }
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
            print("Failed to get AppleSMC service")
            return
        }
        
        let result = IOServiceOpen(service, mach_task_self_, 0, &smcConnection)
        IOObjectRelease(service)
        
        if result != kIOReturnSuccess {
            print("Failed to open SMC connection: \(result)")
            smcConnection = 0
        } else {
            print("SMC connection established successfully")
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
            print("SMC connection not available for charging control")
            showNotification(
                title: "Battery Limiter", 
                body: "Battery reached \(batteryLevel)%. Please unplug to preserve battery health."
            )
            return
        }
        
        // Try multiple methods to stop charging
        
        // Method 1: Set charging current to 0 via SMC
        let result1 = setSMCValue("CH0B", 0)
        
        // Method 2: Try to disable charging via power management
        let result2 = disableChargingViaPowerManagement()
        
        // Method 3: Set battery charge limit via SMC
        let result3 = setSMCValue("CH0B", UInt32(maxChargeLimit))
        
        if result1 == kIOReturnSuccess || result2 || result3 == kIOReturnSuccess {
            print("Successfully stopped charging via multiple methods")
            showNotification(
                title: "Battery Limiter", 
                body: "Charging stopped at \(batteryLevel)% to preserve battery health."
            )
            
            // Force a battery status check to confirm
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                self.updateBatteryInfo()
            }
        } else {
            print("Failed to stop charging via all methods")
            showNotification(
                title: "Battery Limiter", 
                body: "Battery reached \(batteryLevel)%. Please unplug to preserve battery health."
            )
        }
    }
    
    private func disableChargingViaPowerManagement() -> Bool {
        // Try to modify power management settings
        let task = Process()
        task.launchPath = "/usr/bin/pmset"
        task.arguments = ["-c", "acwake", "0"]
        
        do {
            try task.run()
            task.waitUntilExit()
            return task.terminationStatus == 0
        } catch {
            print("Failed to modify power management: \(error)")
            return false
        }
    }
    
    private func setSMCValue(_ key: String, _ value: UInt32) -> IOReturn {
        guard smcConnection != 0 else { return kIOReturnError }
        
        var input = SMCData(
            key: SMCKey(key),
            dataSize: 4,
            dataType: 0,
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
                print("Failed to show notification: \(error.localizedDescription)")
            }
        }
    }
    
    private func requestNotificationPermissions() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, error in
            if granted {
                print("Notification permissions granted")
            } else if let error = error {
                print("Notification permissions denied: \(error.localizedDescription)")
            }
        }
    }
    
    func loadSettings() {
        maxChargeLimit = UserDefaults.standard.integer(forKey: "maxChargeLimit")
        if maxChargeLimit == 0 {
            maxChargeLimit = 80 // Default value
        }
        
        print("Loaded settings: maxChargeLimit = \(maxChargeLimit)%")
    }
    
    func saveSettings() {
        UserDefaults.standard.set(maxChargeLimit, forKey: "maxChargeLimit")
        UserDefaults.standard.synchronize()
        print("Settings saved: maxChargeLimit = \(maxChargeLimit)%")
    }
    
    deinit {
        stopMonitoring()
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
