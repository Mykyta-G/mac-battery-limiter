import SwiftUI
import AppKit
import os.log

@main
struct BatteryLimiterApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem?
    var popover: NSPopover?
    var batteryMonitor: BatteryMonitor?
    private let logger = Logger(subsystem: "com.batterylimiter.app", category: "AppDelegate")
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        logger.info("App launching")
        
        // Check if we have accessibility permissions
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue(): true]
        let accessEnabled = AXIsProcessTrustedWithOptions(options as CFDictionary)
        logger.info("Accessibility enabled: \(accessEnabled)")
        
        // Hide the dock icon since this is a menu bar app
        NSApp.setActivationPolicy(.accessory)
        
        // Create the status item (menu bar icon)
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusItem?.button {
            // Create a unique custom icon - use a different battery symbol with custom color
            let customImage = NSImage(systemSymbolName: "battery.25", accessibilityDescription: "Battery Limiter")
            customImage?.isTemplate = false // Allow custom colors
            
            // Set a unique color to distinguish from system battery
            button.image = customImage
            button.contentTintColor = NSColor.systemOrange // Make it orange to be unique
            button.action = #selector(togglePopover)
            button.target = self
            button.title = "" // Remove the emoji - just use the icon
            button.isEnabled = true
            button.isHidden = false
            
            // Update the button display
            button.needsDisplay = true
            button.needsLayout = true
            
            logger.info("Configured status button")
        } else {
            logger.error("Failed to get status button")
        }
        
        // Ensure the status item is visible
        statusItem?.isVisible = true
        
        // Create the popover
        popover = NSPopover()
        popover?.contentSize = NSSize(width: 300, height: 400)
        popover?.behavior = .transient
        popover?.contentViewController = NSHostingController(rootView: ContentView())
        
        // Initialize battery monitor
        batteryMonitor = BatteryMonitor()
        batteryMonitor?.startMonitoring()
        
        // Register the app to start at login (only if not already registered)
        if !isRegisteredForLogin() {
            registerForLogin()
        } else {
            logger.info("App is already registered for login")
        }
        
        // Register for system notifications
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(systemWillSleep),
            name: NSWorkspace.willSleepNotification,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(systemDidWake),
            name: NSWorkspace.didWakeNotification,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(systemWillPowerOff),
            name: NSWorkspace.willPowerOffNotification,
            object: nil
        )
        
        // Show a visible alert to confirm the app is running
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            let alert = NSAlert()
            alert.messageText = "Battery Limiter is Running!"
            alert.informativeText = "The app will now start automatically when you boot your Mac and continue monitoring even during sleep. Check your menu bar for the battery icon."
            alert.addButton(withTitle: "OK")
            alert.runModal()
        }
    }
    
    @objc func systemWillSleep(_ notification: Notification) {
        logger.info("System going to sleep - Battery Limiter will continue monitoring")
        // Save current state
        batteryMonitor?.saveSettings()
        
        // Ensure the app stays active during sleep
        DispatchQueue.main.async { [weak self] in
            self?.batteryMonitor?.prepareForSleep()
        }
    }
    
    @objc func systemDidWake(_ notification: Notification) {
        logger.info("System woke up - Battery Limiter resuming full monitoring")
        
        // Resume full monitoring
        DispatchQueue.main.async { [weak self] in
            self?.batteryMonitor?.resumeFromSleep()
            
            // Check battery status immediately after wake
            self?.batteryMonitor?.checkBatteryStatus()
        }
    }
    
    @objc func systemWillPowerOff(_ notification: Notification) {
        logger.info("System powering off - Battery Limiter saving state")
        batteryMonitor?.saveSettings()
    }
    
    @objc func togglePopover() {
        if let popover = popover {
            if popover.isShown {
                popover.performClose(nil)
            } else {
                if let button = statusItem?.button {
                    popover.show(relativeTo: button.bounds, of: button, preferredEdge: NSRectEdge.minY)
                }
            }
        }
    }
    
    private func registerForLogin() {
        // Universal login item registration that works on all macOS versions
        let appPath = Bundle.main.bundlePath
        let loginItemPath = "~/Library/LaunchAgents/\(Bundle.main.bundleIdentifier ?? "com.batterylimiter.app").plist"
        
        // Create LaunchAgent plist content with improved settings for background operation
        let plistContent = """
        <?xml version="1.0" encoding="UTF-8"?>
        <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
        <plist version="1.0">
        <dict>
            <key>Label</key>
            <string>\(Bundle.main.bundleIdentifier ?? "com.batterylimiter.app")</string>
            <key>ProgramArguments</key>
            <array>
                <string>\(appPath)/Contents/MacOS/\(Bundle.main.bundleIdentifier ?? "BatteryLimiter")</string>
            </array>
            <key>RunAtLoad</key>
            <true/>
            <key>KeepAlive</key>
            <true/>
            <key>ProcessType</key>
            <string>Background</string>
            <key>StandardOutPath</key>
            <string>/tmp/batterylimiter.log</string>
            <key>StandardErrorPath</key>
            <string>/tmp/batterylimiter.error.log</string>
            <key>ThrottleInterval</key>
            <integer>10</integer>
            <key>WorkingDirectory</key>
            <string>\(appPath)/Contents/Resources</string>
        </dict>
        </plist>
        """
        
        do {
            // Create LaunchAgents directory if it doesn't exist
            let launchAgentsPath = (loginItemPath as NSString).expandingTildeInPath
            let launchAgentsDir = (launchAgentsPath as NSString).deletingLastPathComponent
            try FileManager.default.createDirectory(atPath: launchAgentsDir, withIntermediateDirectories: true)
            
            // Write the plist file
            try plistContent.write(toFile: launchAgentsPath, atomically: true, encoding: .utf8)
            
            // Load the launch agent
            let process = Process()
            process.launchPath = "/bin/launchctl"
            process.arguments = ["load", launchAgentsPath]
            try process.run()
            process.waitUntilExit()
            
            logger.info("Successfully registered for login using LaunchAgent")
        } catch {
            logger.error("Failed to register for login: \(error.localizedDescription)")
            logger.info("You can manually add the app to System Preferences > Users & Groups > Login Items")
        }
    }
    
    private func isRegisteredForLogin() -> Bool {
        let loginItemPath = "~/Library/LaunchAgents/\(Bundle.main.bundleIdentifier ?? "com.batterylimiter.app").plist"
        let expandedPath = (loginItemPath as NSString).expandingTildeInPath
        return FileManager.default.fileExists(atPath: expandedPath)
    }
    
    private func removeFromLogin() {
        let loginItemPath = "~/Library/LaunchAgents/\(Bundle.main.bundleIdentifier ?? "com.batterylimiter.app").plist"
        let expandedPath = (loginItemPath as NSString).expandingTildeInPath
        
        do {
            // Unload the launch agent first
            let process = Process()
            process.launchPath = "/bin/launchctl"
            process.arguments = ["unload", expandedPath]
            try process.run()
            process.waitUntilExit()
            
            // Remove the plist file
            try FileManager.default.removeItem(atPath: expandedPath)
            logger.info("Successfully removed from login items")
        } catch {
            logger.error("Failed to remove from login items: \(error.localizedDescription)")
        }
    }
    
    deinit {
        // Remove observers
        NotificationCenter.default.removeObserver(self)
    }
}
