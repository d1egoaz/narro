//
//  RecordingOverlayWindow.swift
//  Narro
//
//  Created by Claude Code
//

import Cocoa
import SwiftUI

/// A floating, click-through window that displays recording status and audio levels
class RecordingOverlayWindow: NSWindow {

    init<Content: View>(contentView: Content) {
        // Calculate window size and position
        let windowSize = NSSize(width: 280, height: 52)

        // Position at top center of main screen
        let screenFrame = NSScreen.main?.visibleFrame ?? .zero
        let xPosition = screenFrame.midX - (windowSize.width / 2)
        let yPosition = screenFrame.maxY - 60 // 60 points from top

        let contentRect = NSRect(
            x: xPosition,
            y: yPosition,
            width: windowSize.width,
            height: windowSize.height
        )

        super.init(
            contentRect: contentRect,
            styleMask: [.borderless, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )

        // Configure window appearance
        self.isOpaque = false
        self.backgroundColor = .clear
        self.hasShadow = true
        self.level = .floating

        // Make window click-through so it doesn't interfere with user interaction
        self.ignoresMouseEvents = true

        // Don't show in window switcher or mission control
        self.collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle]

        // Prevent window from appearing in the app switcher
        self.isMovable = false
        self.isMovableByWindowBackground = false

        // Set up content view with proper sizing
        let hostingView = NSHostingView(rootView: contentView)
        hostingView.autoresizingMask = [.width, .height]
        self.contentView = hostingView

        // Set min and max content size to enforce our desired dimensions
        self.contentMinSize = windowSize
        self.contentMaxSize = windowSize

        // Initially hidden - controller will show when recording starts
        self.alphaValue = 0
    }

    /// Updates window position when screen configuration changes
    func updatePosition() {
        guard let screen = NSScreen.main else { return }

        let screenFrame = screen.visibleFrame
        let xPosition = screenFrame.midX - (frame.width / 2)
        let yPosition = screenFrame.maxY - 60

        setFrameOrigin(NSPoint(x: xPosition, y: yPosition))
    }

    /// Shows the window with a smooth fade-in animation
    func show() {
        updatePosition()

        // Make sure window is visible before animating
        if !isVisible {
            orderFrontRegardless()
        }

        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.2
            context.timingFunction = CAMediaTimingFunction(name: .easeOut)
            self.animator().alphaValue = 1.0
        }
    }

    /// Hides the window with a smooth fade-out animation
    func hide(completion: (() -> Void)? = nil) {
        NSAnimationContext.runAnimationGroup({ context in
            context.duration = 0.3
            context.timingFunction = CAMediaTimingFunction(name: .easeIn)
            self.animator().alphaValue = 0
        }, completionHandler: {
            self.orderOut(nil)
            completion?()
        })
    }

    override var canBecomeKey: Bool {
        // Prevent window from stealing focus
        return false
    }

    override var canBecomeMain: Bool {
        // Prevent window from becoming main
        return false
    }
}
