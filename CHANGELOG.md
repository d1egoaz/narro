# Changelog

All notable changes to Narro (formerly VTS - Voice Typing Studio) will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.4.2] - 2025-10-31
- New logo and icons.

## [1.4.1] - 2025-10-31

### Fixed
- Allow switching between hold and toggle recording modes without relaunching by re-registering hotkeys when the recording mode changes.
- Restore the App Sandbox configuration so fresh installs can grant accessibility and microphone permissions again.

### Changed
- Default to hold-to-record and harden the recording state machine to avoid duplicate captures.

### Development
- Apply an ad-hoc codesign during unsigned DMG builds so macOS privacy entitlements (mic/accessibility) remain active.
- Refresh documentation and tooling after removing the unused `version.txt` helper.

## [1.2.0] - 2025-10-24

### Rebranding
- **Project renamed from VTS to Narro** - "I narrate" in Latin, better reflects the app's purpose
- Updated all branding, documentation, and project files
- New tagline: "Narrate your thoughts"

### Breaking Changes
- **REMOVED**: Groq provider support (OpenAI-only now)
- **REMOVED**: Deepgram provider support (OpenAI-only now)
- **REMOVED**: Firebase Analytics and all telemetry tracking
- **REMOVED**: Sparkle auto-update functionality

### Added
- **Hold-to-record mode** (push-to-talk): Press and hold hotkey to record, release to stop
- Recording mode selector in Preferences → Hotkeys tab (toggle vs hold modes)
- Automatic app copy script for development (`scripts/copy-to-applications.sh`)
- Real-time mode toggle for OpenAI streaming vs REST API
- Model selection UI for OpenAI transcription models

### Fixed
- OpenAI Realtime API endpoint (changed from conversational to transcription-only)
- Language detection now defaults to English (prevents Chinese misdetection)
- Message types for transcription session (uses `transcription_session.update`)
- Model names for OpenAI transcription API (whisper-1, gpt-4o-transcribe, gpt-4o-mini-transcribe)
- Removed read-only property assignment errors in onboarding and preferences
- WebSocket connection for streaming transcription

### Changed
- Simplified to OpenAI-only architecture for easier maintenance
- System is now focused on transcription quality over provider choice
- Improved transcription accuracy with English language default
- Streamlined onboarding process (removed provider selection, analytics consent)


## [Unreleased]

### 🚀 Coming Soon

- See Roadmap in the README.md for upcoming features and improvements.

---

For more information about each release, visit the [GitHub Releases page](https://github.com/j05u3/VTS/releases).
