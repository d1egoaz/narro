import SwiftUI
import KeyboardShortcuts

struct PreferencesView: View {
    @EnvironmentObject var appState: AppState
    @ObservedObject var apiKeyManager: APIKeyManager
    
    // Access shared instances from AppState instead of creating new ones
    private var captureEngine: CaptureEngine {
        appState.captureEngineService
    }
    
    private var transcriptionService: TranscriptionService {
        appState.transcriptionServiceInstance
    }
    
    private var deviceManager: DeviceManager {
        appState.deviceManagerService
    }
    
    init(apiKeyManager: APIKeyManager) {
        self.apiKeyManager = apiKeyManager
    }
    
    // State for API key editing
    @State private var editingAPIKeys: [STTProviderType: String] = [:]
    @State private var showingTestInjectionView = false
    
    var body: some View {
        TabView {
            // API Configuration Tab
            VStack(spacing: 20) {
                Text("API Configuration")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                GroupBox("Provider Settings") {
                    VStack(alignment: .leading, spacing: 15) {
                        // Provider Selection
                        HStack {
                            Text("Provider:")
                                .frame(width: 100, alignment: .leading)
                            Picker("Provider", selection: Binding(
                                get: { appState.selectedProvider },
                                set: { appState.selectedProvider = $0 }
                            )) {
                                ForEach(STTProviderType.allCases, id: \.self) { provider in
                                    Text(provider.rawValue).tag(provider)
                                }
                            }
                            .pickerStyle(.segmented)
                        }
                        
                        // Model Selection
                        HStack {
                            Text("Model:")
                                .frame(width: 100, alignment: .leading)
                            Picker("Model", selection: Binding(
                                get: { appState.selectedModel },
                                set: { appState.selectedModel = $0 }
                            )) {
                                ForEach(appState.selectedProvider.defaultModels, id: \.self) { model in
                                    Text(model).tag(model)
                                }
                            }
                            .pickerStyle(.menu)
                        }
                        
                        // System Prompt
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("System Prompt:")
                                    .frame(width: 100, alignment: .leading)
                                Spacer()
                                Text("\(appState.systemPrompt.count) characters")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            ZStack(alignment: .topLeading) {
                                // Background with border similar to TextField
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(Color.primary.opacity(0.2), lineWidth: 1)
                                    .background(
                                        RoundedRectangle(cornerRadius: 6)
                                            .fill(Color(NSColor.textBackgroundColor))
                                    )
                                
                                // ScrollView with TextEditor for multi-line support
                                ScrollView(.vertical, showsIndicators: true) {
                                    TextEditor(text: $appState.systemPrompt)
                                        .font(.system(size: 13))
                                        .scrollContentBackground(.hidden)
                                        .background(Color.clear)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 6)
                                        .frame(minHeight: 60) // Approximately 3 lines
                                }
                                .frame(height: 60) // Fixed height for exactly 3 lines
                                
                                // Placeholder text when empty
                                if appState.systemPrompt.isEmpty {
                                    Text("Optional system prompt to improve transcription accuracy")
                                        .font(.system(size: 13))
                                        .foregroundColor(.secondary)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 10)
                                        .allowsHitTesting(false)
                                }
                            }
                        }
                        
                        // Help text
                        Text("System prompts help improve accuracy for domain-specific language, names, or technical terms.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                }
                
                GroupBox("API Keys") {
                    VStack(alignment: .leading, spacing: 15) {
                        Text("Configure API Keys")
                            .font(.headline)
                        
                        Text("Enter your API keys for each provider. Keys are stored securely in your macOS keychain.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        ForEach(STTProviderType.allCases, id: \.self) { provider in
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Image(systemName: provider.iconName)
                                        .foregroundColor(provider == .openai ? .green : .orange)
                                        .frame(width: 20)
                                    
                                    Text(provider.displayName)
                                        .font(.headline)
                                    
                                    Spacer()
                                    
                                    // Status indicator
                                    if apiKeyManager.hasAPIKey(for: provider) {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(.green)
                                            .help("API key configured")
                                    } else {
                                        Image(systemName: "exclamationmark.circle.fill")
                                            .foregroundColor(.orange)
                                            .help("API key required")
                                    }
                                }
                                
                                HStack {
                                    if editingAPIKeys[provider] != nil {
                                        // Editing mode
                                        SecureField("Enter your \(provider.displayName) API key", text: Binding(
                                            get: { editingAPIKeys[provider] ?? "" },
                                            set: { editingAPIKeys[provider] = $0 }
                                        ))
                                        .textFieldStyle(.roundedBorder)
                                        
                                        Button("Save") {
                                            saveAPIKey(for: provider)
                                        }
                                        .buttonStyle(.borderedProminent)
                                        .disabled(editingAPIKeys[provider]?.isEmpty != false)
                                        
                                        Button("Cancel") {
                                            editingAPIKeys[provider] = nil
                                        }
                                        .buttonStyle(.bordered)
                                    } else {
                                        // Display mode
                                        HStack {
                                            if apiKeyManager.hasAPIKey(for: provider) {
                                                Text("••••••••••••••••")
                                                    .font(.system(.body, design: .monospaced))
                                                    .foregroundColor(.secondary)
                                            } else {
                                                Text("No API key configured")
                                                    .foregroundColor(.secondary)
                                                    .italic()
                                            }
                                            
                                            Spacer()
                                            
                                            if apiKeyManager.hasAPIKey(for: provider) {
                                                Button("Edit") {
                                                    editingAPIKeys[provider] = ""
                                                }
                                                .buttonStyle(.bordered)
                                                
                                                Button("Remove") {
                                                    removeAPIKey(for: provider)
                                                }
                                                .buttonStyle(.bordered)
                                                .foregroundColor(.red)
                                            } else {
                                                Button("Add Key") {
                                                    editingAPIKeys[provider] = ""
                                                }
                                                .buttonStyle(.borderedProminent)
                                            }
                                        }
                                    }
                                }
                            }
                            .padding(.bottom, 8)
                        }
                    }
                    .padding()
                }
                
                Spacer()
            }
            .padding()
            .tabItem {
                Image(systemName: "key.fill")
                Text("API Keys")
            }
            
            // Microphone Tab (unchanged)
            VStack(spacing: 20) {
                Text("Microphone Settings")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                GroupBox("Device Priority") {
                    VStack(alignment: .leading, spacing: 15) {
                        HStack {
                            Text("Available Devices:")
                                .font(.headline)
                            Spacer()
                            Button("Refresh") {
                                deviceManager.updateAvailableDevices()
                            }
                            .buttonStyle(.bordered)
                        }
                        
                        if deviceManager.availableDevices.isEmpty {
                            Text("No microphones detected")
                                .foregroundColor(.secondary)
                                .italic()
                        } else {
                            // Available devices list
                            VStack(alignment: .leading, spacing: 5) {
                                ForEach(deviceManager.availableDevices) { device in
                                    HStack {
                                        Image(systemName: "mic.fill")
                                            .foregroundColor(.blue)
                                        Text(device.name)
                                            .font(.body)
                                        if device.isDefault {
                                            Text("(System Default)")
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }
                                        Spacer()
                                        Button("+") {
                                            deviceManager.addDeviceToPriorities(device.id)
                                        }
                                        .buttonStyle(.bordered)
                                        .disabled(deviceManager.devicePriorities.contains(device.id))
                                    }
                                    .padding(.vertical, 2)
                                }
                            }
                            
                            Divider()
                            
                            // Priority list
                            VStack(alignment: .leading, spacing: 10) {
                                HStack {
                                    Text("Priority Order:")
                                        .font(.headline)
                                    Spacer()
                                    if !deviceManager.devicePriorities.isEmpty {
                                        Text("Drag to reorder")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                                
                                if deviceManager.devicePriorities.isEmpty {
                                    Text("No priority set - will use system default")
                                        .foregroundColor(.secondary)
                                        .italic()
                                        .frame(height: 40)
                                } else {
                                    List {
                                        ForEach(deviceManager.devicePriorities, id: \.self) { deviceID in
                                            HStack(spacing: 12) {
                                                // Priority number
                                                Text("\(deviceManager.devicePriorities.firstIndex(of: deviceID)! + 1).")
                                                    .font(.caption)
                                                    .foregroundColor(.secondary)
                                                    .frame(width: 20, alignment: .trailing)
                                                
                                                // Drag handle
                                                Image(systemName: "line.3.horizontal")
                                                    .foregroundColor(.secondary)
                                                    .imageScale(.medium)
                                                
                                                // Device name
                                                Text(deviceManager.getDeviceName(for: deviceID))
                                                    .font(.body)
                                                
                                                // Active indicator
                                                if deviceID == deviceManager.preferredDeviceID {
                                                    Text("(Active)")
                                                        .font(.caption)
                                                        .foregroundColor(.green)
                                                        .fontWeight(.medium)
                                                }
                                                
                                                Spacer()
                                                
                                                // Remove button
                                                Button("−") {
                                                    deviceManager.removeDeviceFromPriorities(deviceID)
                                                }
                                                .buttonStyle(.bordered)
                                                .foregroundColor(.red)
                                            }
                                            .listRowSeparator(.hidden)
                                            .listRowBackground(Color.clear)
                                        }
                                        .onMove(perform: { source, destination in
                                            deviceManager.moveDevice(from: IndexSet(source), to: destination)
                                        })
                                    }
                                    .listStyle(.plain)
                                    .frame(height: CGFloat(deviceManager.devicePriorities.count * 40))
                                }
                            }
                        }
                    }
                    .padding()
                }
                
                Spacer()
            }
            .padding()
            .tabItem {
                Image(systemName: "mic.fill")
                Text("Microphones")
            }
            
            // Permissions Tab (unchanged)
            VStack(spacing: 20) {
                Text("Permissions & Accessibility")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                GroupBox("Required Permissions") {
                    VStack(alignment: .leading, spacing: 20) {
                        // Microphone Permission
                        HStack {
                            Image(systemName: captureEngine.permissionGranted ? "checkmark.circle.fill" : "xmark.circle.fill")
                                .foregroundColor(captureEngine.permissionGranted ? .green : .red)
                                .font(.title2)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Microphone Access")
                                    .font(.headline)
                                Text(captureEngine.permissionGranted ? "Granted" : "Required for audio recording")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            if !captureEngine.permissionGranted {
                                Button("Grant") {
                                    // Permission will be requested automatically
                                }
                                .buttonStyle(.bordered)
                            }
                        }
                        
                        Divider()
                        
                        // Accessibility Permission
                        HStack {
                            Image(systemName: transcriptionService.injector.hasAccessibilityPermission ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                                .foregroundColor(transcriptionService.injector.hasAccessibilityPermission ? .green : .orange)
                                .font(.title2)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Text("Accessibility Access")
                                        .font(.headline)
                                    
                                    if transcriptionService.injector.hasAccessibilityPermission {
                                        Button("Debug") {
                                            showingTestInjectionView = true
                                        }
                                        .buttonStyle(.bordered)
                                        .controlSize(.mini)
                                    }
                                }
                                
                                Text(transcriptionService.injector.hasAccessibilityPermission ? "Granted - Text injection enabled" : "Required to insert text like native dictation")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            VStack(spacing: 4) {
                                if !transcriptionService.injector.hasAccessibilityPermission {
                                    Button("Grant") {
                                        transcriptionService.injector.requestAccessibilityPermission()
                                    }
                                    .buttonStyle(.bordered)
                                }
                            }
                        }
                    }
                    .padding()
                }
                
                GroupBox("How It Works") {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("VTS works like native macOS dictation:")
                            .font(.headline)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("1.")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text("Press \(appState.hotkeyManagerService.currentHotkeyString) anywhere in macOS to start recording")
                            }
                            
                            HStack {
                                Text("2.")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text("Speak your text while the status bar shows 🔴")
                            }
                            
                            HStack {
                                Text("3.")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text("Press \(appState.hotkeyManagerService.currentHotkeyString) again to stop and insert text at cursor")
                            }
                        }
                        
                        Text("Accessibility permission allows VTS to type text directly into any app, just like built-in dictation.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                }
                
                Spacer()
            }
            .padding()
            .tabItem {
                Image(systemName: "hand.raised.fill")
                Text("Permissions")
            }
            
            // Global Hotkeys Tab
            VStack(spacing: 20) {
                Text("Global Hotkeys")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                GroupBox("Recording Hotkey") {
                    VStack(alignment: .leading, spacing: 15) {
                        Text("Configure the global keyboard shortcut to toggle recording on/off.")
                            .foregroundColor(.secondary)
                        
                        HStack {
                            Text("Toggle Recording:")
                                .frame(width: 140, alignment: .leading)
                            
                            KeyboardShortcuts.Recorder(for: .toggleRecording)
                                .onAppear {
                                    // Refresh hotkey string when view appears
                                    appState.hotkeyManagerService.refreshHotkeyString()
                                }
                            
                            Spacer()
                            
                            Button("Reset to Default") {
                                KeyboardShortcuts.reset(.toggleRecording)
                                // Refresh hotkey string after reset
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                    appState.hotkeyManagerService.refreshHotkeyString()
                                }
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("• The hotkey works system-wide, even when VTS is not the active application")
                            Text("• Current shortcut: \(appState.hotkeyManagerService.currentHotkeyString)")
                            Text("• Click in the recorder above to set a new shortcut")
                        }
                        .font(.caption)
                        .foregroundColor(.secondary)
                    }
                    .padding()
                }
                
                Spacer()
            }
            .padding()
            .tabItem {
                Image(systemName: "keyboard")
                Text("Hotkeys")
            }
        }
        .frame(width: 600, height: 600)
        .sheet(isPresented: $showingTestInjectionView) {
            TextInjectionTestView(isPresented: $showingTestInjectionView)
                .environmentObject(appState)
        }

    }
    
    private func saveAPIKey(for provider: STTProviderType) {
        guard let key = editingAPIKeys[provider], !key.isEmpty else { return }
        
        do {
            try apiKeyManager.storeAPIKey(key, for: provider)
            editingAPIKeys[provider] = nil
        } catch {
            print("Failed to store API key: \(error)")
        }
    }
    
    private func removeAPIKey(for provider: STTProviderType) {
        do {
            try apiKeyManager.deleteAPIKey(for: provider)
        } catch {
            print("Failed to delete API key: \(error)")
        }
    }
}



#Preview {
    PreferencesView(apiKeyManager: APIKeyManager())
        .environmentObject(AppState())
} 