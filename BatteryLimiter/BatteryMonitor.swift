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
    
    private var timer: Timer?
    private var isInSleepMode: Bool = false
    private var lastBatteryCheck: Date = Date()
    
    func startMonitoring() {
        isMonitoring = true
        checkBatteryStatus()
        
        // Check battery status every 15 seconds for better responsiveness
        timer = Timer.scheduledTimer(withTimeInterval: 15.0, repeats: true) { _ in
            self.checkBatteryStatus()
        }
        
        // Load saved settings
        loadSettings()
        
        // Request notification permissions
        requestNotificationPermissions()
    }
    
    func stopMonitoring() {
        isMonitoring = false
        timer?.invalidate()
        timer = nil
    }
    
    func checkBatteryStatus() {
        // Don't check too frequently to avoid excessive CPU usage
        let timeSinceLastCheck = Date().timeIntervalSince(lastBatteryCheck)
        if timeSinceLastCheck < 10.0 {
            return
        }
        
        lastBatteryCheck = Date()
        updateBatteryInfo()
        
        // Check if we need to stop charging
        if isCharging && batteryLevel >= maxChargeLimit {
            stopCharging()
        }
        
        // Log battery status for debugging
        print("Battery: \(batteryLevel)%, Charging: \(isCharging), Plugged: \(isPluggedIn)")
    }
    
    func prepareForSleep() {
        print("Preparing for sleep mode...")
        isInSleepMode = true
        
        // Save current settings
        saveSettings()
        
        // Reduce monitoring frequency during sleep
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 60.0, repeats: true) { _ in
            self.checkBatteryStatus()
        }
        
        print("Battery Limiter is now in sleep mode with reduced monitoring")
    }
    
    func resumeFromSleep() {
        print("Resuming from sleep mode...")
        isInSleepMode = false
        
        // Restore normal monitoring frequency
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 15.0, repeats: true) { _ in
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
    
    private func stopCharging() {
        // This is a simplified approach - in a real implementation,
        // you would need to use more advanced methods to control charging
        
        // For now, we'll just log the action and show a notification
        print("Battery level reached \(batteryLevel)%. Should stop charging at \(maxChargeLimit)%")
        
        // Show notification to user
        showNotification(
            title: "Battery Limiter", 
            body: "Battery reached \(batteryLevel)%. Consider unplugging to preserve battery health."
        )
        
        // You could implement more sophisticated charging control here:
        // - Use SMC (System Management Controller) commands
        // - Modify power management settings
        // - Send notifications to the user
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
