import SwiftUI
import UserNotifications

struct ContentView: View {
    @StateObject private var batteryMonitor = BatteryMonitor()
    @State private var showingSettings = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: 16) {
                HStack {
                    Image(systemName: "battery.100")
                        .font(.title)
                        .foregroundColor(.green)
                        .padding(.leading, 4)
                    
                    Text("Battery Limiter")
                        .font(.title2)
                        .fontWeight(.bold)
                        .padding(.leading, 4)
                    
                    Spacer()
                    
                    Button(action: {
                        showingSettings.toggle()
                    }) {
                        Image(systemName: "gear")
                            .font(.title3)
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .padding(.trailing, 4)
                }
                
                // Error Message Display
                if let errorMessage = batteryMonitor.errorMessage {
                    HStack(spacing: 8) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.red)
                        Text(errorMessage)
                            .font(.caption)
                            .foregroundColor(.red)
                            .multilineTextAlignment(.leading)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.red.opacity(0.1))
                    .cornerRadius(8)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 32)
            .padding(.bottom, 20)
            
            Divider()
                .padding(.horizontal, 20)
            
            // Battery Status Section
            VStack(spacing: 24) {
                // Battery Level
                VStack(spacing: 8) {
                    Text("\(batteryMonitor.batteryLevel)%")
                        .font(.system(size: 56, weight: .bold, design: .rounded))
                        .foregroundColor(batteryColor)
                    
                    Text("Battery Level")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .fontWeight(.medium)
                }
                .padding(.top, 8)
                
                // Status Indicators
                HStack(spacing: 24) {
                    StatusIndicator(
                        icon: batteryMonitor.isCharging ? "bolt.fill" : "bolt.slash",
                        text: batteryMonitor.isCharging ? "Charging" : "Not Charging",
                        color: batteryMonitor.isCharging ? .green : .orange
                    )
                    
                    StatusIndicator(
                        icon: batteryMonitor.isPluggedIn ? "poweroutlet.type.f.fill" : "poweroutlet.type.f",
                        text: batteryMonitor.isPluggedIn ? "Plugged In" : "On Battery",
                        color: batteryMonitor.isPluggedIn ? .blue : .gray
                    )
                }
                
                // Monitoring Status
                HStack(spacing: 8) {
                    Circle()
                        .fill(batteryMonitor.isMonitoring ? Color.green : Color.red)
                        .frame(width: 10, height: 10)
                    
                    Text(batteryMonitor.isMonitoring ? "Monitoring Active" : "Monitoring Inactive")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .fontWeight(.medium)
                }
                
                // Last Update Time
                Text("Last updated: \(timeAgoString(from: batteryMonitor.lastUpdateTime))")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.top, 4)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 20)
            
            Divider()
                .padding(.horizontal, 20)
            
            // Charge Limit Section
            VStack(spacing: 16) {
                HStack {
                    Text("Max Charge Limit")
                        .font(.headline)
                        .fontWeight(.semibold)
                    Spacer()
                    Text("\(batteryMonitor.maxChargeLimit)%")
                        .font(.headline)
                        .foregroundColor(.blue)
                        .fontWeight(.bold)
                }
                
                Slider(value: Binding(
                    get: { Double(batteryMonitor.maxChargeLimit) },
                    set: { batteryMonitor.setMaxChargeLimit(Int($0)) }
                ), in: 20...100, step: 5)
                .accentColor(.blue)
                
                HStack {
                    Text("20%")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("100%")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                // Charge Limit Status
                if batteryMonitor.isCharging && batteryMonitor.batteryLevel >= batteryMonitor.maxChargeLimit {
                    HStack(spacing: 8) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.orange)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Charge limit reached!")
                                .font(.caption)
                                .foregroundColor(.orange)
                                .fontWeight(.semibold)
                            Text("Charging will be stopped automatically.")
                                .font(.caption2)
                                .foregroundColor(.orange)
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.orange.opacity(0.1))
                    .cornerRadius(8)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 20)
            
            Spacer(minLength: 20)
            
            Divider()
                .padding(.horizontal, 20)
            
            // Action Button
            VStack(spacing: 16) {
                Button(action: {
                    if batteryMonitor.isMonitoring {
                        batteryMonitor.stopMonitoring()
                    } else {
                        batteryMonitor.startMonitoring()
                    }
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: batteryMonitor.isMonitoring ? "stop.fill" : "play.fill")
                        Text(batteryMonitor.isMonitoring ? "Stop Monitoring" : "Start Monitoring")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                
                // Footer
                Text("© 2025 Battery Limiter")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.top, 8)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 32)
        }
        .frame(width: 320, height: 600)
        .background(Color(NSColor.controlBackgroundColor))
        .onAppear {
            batteryMonitor.loadSettings()
        }
        .sheet(isPresented: $showingSettings) {
            SettingsView(batteryMonitor: batteryMonitor)
        }
    }
    
    private var batteryColor: Color {
        if batteryMonitor.batteryLevel <= 20 {
            return .red
        } else if batteryMonitor.batteryLevel <= 50 {
            return .orange
        } else {
            return .green
        }
    }
    
    private func timeAgoString(from date: Date) -> String {
        let interval = Date().timeIntervalSince(date)
        
        if interval < 60 {
            return "Just now"
        } else if interval < 3600 {
            let minutes = Int(interval / 60)
            return "\(minutes) min ago"
        } else {
            let hours = Int(interval / 3600)
            return "\(hours) hour\(hours == 1 ? "" : "s") ago"
        }
    }
}

struct StatusIndicator: View {
    let icon: String
    let text: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
                .frame(width: 24, height: 24)
            
            Text(text)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .fontWeight(.medium)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(Color.secondary.opacity(0.05))
        .cornerRadius(10)
    }
}

struct SettingsView: View {
    @ObservedObject var batteryMonitor: BatteryMonitor
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            Form {
                Section("Battery Settings") {
                    HStack {
                        Text("Max Charge Limit")
                        Spacer()
                        Text("\(batteryMonitor.maxChargeLimit)%")
                            .foregroundColor(.blue)
                    }
                    
                    Slider(value: Binding(
                        get: { Double(batteryMonitor.maxChargeLimit) },
                        set: { batteryMonitor.setMaxChargeLimit(Int($0)) }
                    ), in: 20...100, step: 5)
                }
                
                Section("Information") {
                    Text("This app helps preserve your Mac's battery health by monitoring charging levels and suggesting when to unplug.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle("Settings")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .frame(width: 400, height: 300)
    }
}

#Preview {
    ContentView()
}
