import SwiftUI

struct ContentView: View {
    @StateObject private var batteryMonitor = BatteryMonitor()
    @State private var showingSettings = false
    
    var body: some View {
        VStack(spacing: 20) {
            // Header
            HStack {
                Image(systemName: "battery.100")
                    .font(.title)
                    .foregroundColor(.green)
                
                Text("Battery Limiter")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Spacer()
                
                Button(action: {
                    showingSettings.toggle()
                }) {
                    Image(systemName: "gear")
                        .font(.title3)
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding(.horizontal)
            
            Divider()
            
            // Battery Status
            VStack(spacing: 15) {
                // Battery Level
                VStack {
                    Text("\(batteryMonitor.batteryLevel)%")
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .foregroundColor(batteryColor)
                    
                    Text("Battery Level")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                // Status Indicators
                HStack(spacing: 20) {
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
                HStack {
                    Circle()
                        .fill(batteryMonitor.isMonitoring ? Color.green : Color.red)
                        .frame(width: 8, height: 8)
                    
                    Text(batteryMonitor.isMonitoring ? "Monitoring Active" : "Monitoring Inactive")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Divider()
            
            // Charge Limit
            VStack(spacing: 10) {
                HStack {
                    Text("Max Charge Limit")
                        .font(.headline)
                    Spacer()
                    Text("\(batteryMonitor.maxChargeLimit)%")
                        .font(.headline)
                        .foregroundColor(.blue)
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
            }
            .padding(.horizontal)
            
            Divider()
            
            // Action Buttons
            HStack(spacing: 15) {
                Button(action: {
                    if batteryMonitor.isMonitoring {
                        batteryMonitor.stopMonitoring()
                    } else {
                        batteryMonitor.startMonitoring()
                    }
                }) {
                    HStack {
                        Image(systemName: batteryMonitor.isMonitoring ? "stop.fill" : "play.fill")
                        Text(batteryMonitor.isMonitoring ? "Stop" : "Start")
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                
                Button(action: {
                    batteryMonitor.checkBatteryStatus()
                }) {
                    HStack {
                        Image(systemName: "arrow.clockwise")
                        Text("Refresh")
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
            }
            .padding(.horizontal)
            
            Spacer()
            
            // Footer
            Text("Click the menu bar icon to access this app")
                .font(.caption2)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .padding()
        .frame(width: 300, height: 400)
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
}

struct StatusIndicator: View {
    let icon: String
    let text: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 5) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(text)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
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
