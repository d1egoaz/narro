//
//  RecordingOverlayController.swift
//  Narro
//
//  Created by Claude Code
//

import Cocoa
import SwiftUI
import Combine

/// Manages the lifecycle of the floating recording overlay window
@MainActor
class RecordingOverlayController {
    private var overlayWindow: RecordingOverlayWindow?
    private var cancellables = Set<AnyCancellable>()
    private weak var appState: AppState?

    // User preference - can be disabled via settings
    @AppStorage("showRecordingOverlay") private var showOverlay = true

    init() {}

    /// Connects the overlay to the app state and begins observing changes
    func setup(with appState: AppState) {
        self.appState = appState

        // Create the overlay window with reactive content
        let overlayView = RecordingOverlayView(
            isRecording: appState.isRecording,
            isProcessing: appState.isProcessing,
            audioLevel: appState.audioLevel
        )

        overlayWindow = RecordingOverlayWindow(contentView: overlayView)

        // Observe recording state changes
        appState.$isRecording
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isRecording in
                self?.handleRecordingStateChange(isRecording: isRecording)
            }
            .store(in: &cancellables)

        // Observe processing state changes
        appState.$isProcessing
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isProcessing in
                self?.handleProcessingStateChange(isProcessing: isProcessing)
            }
            .store(in: &cancellables)

        // Observe audio level changes to update the view
        appState.$audioLevel
            .receive(on: DispatchQueue.main)
            .sink { [weak self] audioLevel in
                self?.updateView()
            }
            .store(in: &cancellables)

        // Listen for screen configuration changes (display reconnect, resolution change)
        NotificationCenter.default.publisher(for: NSApplication.didChangeScreenParametersNotification)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.overlayWindow?.updatePosition()
            }
            .store(in: &cancellables)
    }

    private func handleRecordingStateChange(isRecording: Bool) {
        guard showOverlay else { return }
        updateView()

        if isRecording {
            // Recording started - show the overlay
            overlayWindow?.show()
        } else {
            // Recording stopped - hide if nothing is active
            checkAndHideIfIdle()
        }
    }

    private func handleProcessingStateChange(isProcessing: Bool) {
        guard showOverlay else { return }
        updateView()

        if isProcessing {
            // Processing started - show or keep visible
            if overlayWindow?.alphaValue == 0 {
                overlayWindow?.show()
            }
        } else {
            // Processing finished - hide if nothing is active
            checkAndHideIfIdle()
        }
    }

    /// Hide the overlay if both recording and processing are complete
    private func checkAndHideIfIdle() {
        guard let appState = appState else { return }

        // Only hide if both states are false (nothing active)
        if !appState.isRecording && !appState.isProcessing {
            overlayWindow?.hide()
        }
    }

    /// Updates the overlay view content with current app state
    private func updateView() {
        guard let appState = appState else { return }

        let updatedView = RecordingOverlayView(
            isRecording: appState.isRecording,
            isProcessing: appState.isProcessing,
            audioLevel: appState.audioLevel
        )

        if let contentView = overlayWindow?.contentView as? NSHostingView<RecordingOverlayView> {
            contentView.rootView = updatedView
        }
    }

    /// Manually shows the overlay (for testing or user preference)
    func show() {
        guard showOverlay else { return }
        updateView()
        overlayWindow?.show()
    }

    /// Manually hides the overlay
    func hide() {
        overlayWindow?.hide()
    }

    /// Cleanup on app termination
    func teardown() {
        cancellables.removeAll()
        overlayWindow?.orderOut(nil)
        overlayWindow = nil
    }
}
