# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**Narro** is a macOS menu bar application that provides voice-to-text transcription using OpenAI's API. It's a streamlined fork of VTS, focused exclusively on OpenAI integration with support for both REST (whisper-1) and real-time streaming transcription (gpt-4o-transcribe, gpt-4o-mini-transcribe).

## Build Commands

### Development Build
```bash
# Open in Xcode
open NarroApp.xcodeproj

# Build via command line (Debug configuration)
xcodebuild -project NarroApp.xcodeproj -scheme NarroApp -configuration Debug build

# Build and copy to ~/Applications for testing
xcodebuild -project NarroApp.xcodeproj -scheme NarroApp -configuration Debug build && \
  cp -R ~/Library/Developer/Xcode/DerivedData/NarroApp-*/Build/Products/Debug/Narro.app ~/Applications/
```

### Release Build
```bash
# Build Release configuration
xcodebuild -project NarroApp.xcodeproj -scheme NarroApp -configuration Release clean build

# Create unsigned DMG (no Developer ID certificate needed)
./scripts/build-dmg.sh --skip-signing

# Full release process (version bump, tag, build, create GitHub release)
./scripts/release.sh v1.x.x
```

### Running from Command Line (for debugging)
```bash
# Launch app and see console output including print() statements
/Users/diego.albeiroalvarezzuluag/Applications/Narro.app/Contents/MacOS/Narro 2>&1
```

## Architecture

### Core Components

**NarroApp/NarroApp.swift** - Main application entry point and state management
- `AppState` class: Central @MainActor class managing all app state and coordinating services
- Contains instances of all major services (CaptureEngine, TranscriptionServices, DeviceManager, etc.)
- Uses Combine framework to propagate state changes between nested ObservableObjects

**Provider Protocol Pattern** - Abstraction for transcription services
- `RestSTTProvider` protocol (`NarroApp/VTS/Protocols/RestSTTProvider.swift`): For REST-based transcription
- `StreamingSTTProvider` protocol (`NarroApp/VTS/Protocols/StreamingSTTProvider.swift`): For real-time streaming
- Current implementation: `OpenAIRestProvider` and `OpenAIStreamingProvider` in `NarroApp/VTS/Providers/`

**Service Layer** (`NarroApp/VTS/Services/`)
- `CaptureEngine.swift`: Audio capture using AVAudioEngine with Core Audio device management
- `RestTranscriptionService.swift`: Orchestrates REST-based transcription (whisper-1)
- `StreamingTranscriptionService.swift`: Orchestrates real-time streaming transcription (gpt-4o models)
- `DeviceManager.swift`: Microphone priority management with automatic fallback
- `TextInjector.swift`: Injects transcribed text into active applications via accessibility APIs
- `NotificationManager.swift`: User notifications for errors and completion
- `SimpleHotkeyManager.swift`: Global hotkey registration using KeyboardShortcuts library

**UI Layer**
- Menu bar-only app (no dock icon) - controlled by `LSUIElement=true` in `Info.plist`
- `StatusBarController` manages the menu bar icon and popover
- `PreferencesView`: Settings interface for API keys, models, prompts, device priority
- `OnboardingView` and `OnboardingSteps/`: Multi-step onboarding flow for first launch
- `RecordingOverlayWindow/View/Controller`: Floating overlay shown during recording

### Key Data Flow

1. **Audio Capture**: User presses hotkey → `SimpleHotkeyManager` → `AppState.toggleRecording()` → `CaptureEngine.start()` → produces `AsyncThrowingStream<Data, Error>`
2. **Transcription**: Audio stream → `RestTranscriptionService` or `StreamingTranscriptionService` → appropriate provider → API response
3. **Text Injection**: Final transcript → `TextInjector.injectText()` → active application via CGEventPost
4. **State Updates**: Services update `@Published` properties → Combine propagates changes → UI updates reactively

### Recording Modes

Two recording modes controlled by `RecordingMode` enum in `NarroApp.swift`:
- **Toggle**: Press hotkey once to start, press again to stop
- **Hold**: Press and hold hotkey to record, release to stop

Mode switching is handled via Combine observation (NOT `didSet`) because `@Published` properties don't fire `didSet` when changed via SwiftUI bindings.

## Important Patterns & Gotchas

### SwiftUI + Combine State Management

**Problem**: `@Published` properties don't trigger `didSet` when changed via SwiftUI bindings.

**Solution**: Use Combine's `$property.sink` pattern instead:
```swift
// ❌ This doesn't work with SwiftUI bindings
@Published var recordingMode: RecordingMode = .toggle {
    didSet {
        // This won't fire when changed from SwiftUI!
    }
}

// ✅ Correct approach
@Published var recordingMode: RecordingMode = .toggle

init() {
    $recordingMode
        .dropFirst() // Skip initial value
        .sink { [weak self] mode in
            self?.handleModeChange(mode)
        }
        .store(in: &cancellables)
}
```

### Xcode Project File Management

When adding new Swift files, they must be registered in `NarroApp.xcodeproj/project.pbxproj`:
- Add to `PBXBuildFile` section
- Add to `PBXFileReference` section
- Add to `PBXSourcesBuildPhase`
- Use UUIDs for all identifiers

Use the `Read` tool to examine existing entries as templates.

### Debugging Print Statements

Swift `print()` statements go to stderr, not the unified logging system:
```bash
# See print() output from running app
/path/to/Narro.app/Contents/MacOS/Narro 2>&1 | grep "pattern"

# View unified log (system logging only)
log stream --predicate 'process == "Narro"' --level debug
```

### Accessibility Permissions During Development

Each new build gets a different code signature, causing macOS to treat it as a "new" app:
- Accessibility permission must be re-granted after builds that change code signature
- Solution: Remove old entries from System Settings > Privacy & Security > Accessibility
- For testing onboarding: Change `PRODUCT_BUNDLE_IDENTIFIER` to reset all permissions

### NSWindow + SwiftUI Sizing

When embedding SwiftUI views in NSWindow via NSHostingView, intrinsic content size takes precedence:
- Set `window.contentMinSize` and `window.contentMaxSize` to enforce dimensions
- Use `.frame(maxWidth: .infinity, maxHeight: .infinity)` in SwiftUI view to fill available space
- Don't set explicit `.frame(width:, height:)` on root SwiftUI view

## Testing

Currently manual testing only. Key test scenarios:

1. **Recording Modes**: Test Toggle and Hold modes with mode switching (no restart required)
2. **Device Switching**: Test microphone priority fallback when devices connect/disconnect
3. **Text Injection**: Use built-in Text Injection Test Suite in settings
4. **Onboarding Flow**: Change bundle identifier to test from clean state

## Version Management

Version is stored in `NarroApp/Info.plist`:
- `CFBundleShortVersionString`: Display version (e.g., "1.3.0")
- `CFBundleVersion`: Build version (typically same as short version)

Update via:
```bash
# Manual
/usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString 1.x.x" NarroApp/Info.plist
/usr/libexec/PlistBuddy -c "Set :CFBundleVersion 1.x.x" NarroApp/Info.plist

# Automated (via release script)
./scripts/release.sh v1.x.x
```

## Package Dependencies

Managed via Swift Package Manager (SPM) in Xcode:
- **KeyboardShortcuts** (sindresorhus): Global hotkey registration
- **KeychainAccess** (kishikawakatsumi): Secure API key storage

Dependencies resolve automatically when opening project in Xcode.

## Security & Privacy

- API keys stored in macOS Keychain via `APIKeyManager` class
- Microphone permission required (NSMicrophoneUsageDescription in Info.plist)
- Accessibility permission required for text injection (NSAccessibilityUsageDescription)
- No analytics or telemetry (removed from fork)
- All API communication over HTTPS

## Common Workflows

### Adding a New Transcription Provider

1. Create provider class implementing `RestSTTProvider` or `StreamingSTTProvider` in `NarroApp/VTS/Providers/`
2. Add provider case to `STTProviderType` enum in `TranscriptionModels.swift`
3. Update provider selection in `AppState.setupTranscriptionServices()`
4. Add model list to provider type's `restModels` or `realtimeModels`

### Adding a New UI Component

1. Create SwiftUI view in `NarroApp/VTS/Views/`
2. If adding files via command line, register in Xcode project.pbxproj
3. Use `@EnvironmentObject` to access `AppState`
4. Inject via `environmentObject(appState)` from parent view

### Debugging Transcription Issues

1. Launch app from command line to see all console output
2. Check API key validity in Keychain Access
3. Verify microphone permission in System Settings
4. Test with different models (whisper-1 is most reliable)
5. Check system prompt length (max 1024 characters for real-time)

### Release Process

1. Update version in Info.plist
2. Build Release configuration and test thoroughly
3. Run `./scripts/release.sh vX.Y.Z`
4. Script automatically:
   - Updates Info.plist version
   - Builds universal DMG
   - Creates git tag
   - Creates GitHub release with DMG and checksums
