//
//  RecordingOverlayView.swift
//  Narro
//
//  Created by Claude Code
//

import SwiftUI

struct RecordingOverlayView: View {
    let isRecording: Bool
    let isProcessing: Bool
    let audioLevel: Float

    var body: some View {
        HStack(spacing: 12) {
            // Status indicator
            statusIndicator

            // Audio level visualization (only show when recording)
            if isRecording {
                AudioLevelView(audioLevel: audioLevel, isRecording: true)
            } else if isProcessing {
                processingText
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(backgroundView)
    }

    @ViewBuilder
    private var statusIndicator: some View {
        if isRecording {
            // Red pulsing dot for recording
            Circle()
                .fill(Color.red)
                .frame(width: 12, height: 12)
                .overlay(
                    Circle()
                        .stroke(Color.red.opacity(0.3), lineWidth: 2)
                        .scaleEffect(pulseAnimation ? 1.5 : 1.0)
                        .opacity(pulseAnimation ? 0 : 1)
                )
                .onAppear {
                    withAnimation(
                        .easeInOut(duration: 1.0)
                        .repeatForever(autoreverses: false)
                    ) {
                        pulseAnimation = true
                    }
                }
        } else if isProcessing {
            // Blue pulsing dot for processing
            Circle()
                .fill(Color.blue)
                .frame(width: 12, height: 12)
                .overlay(
                    Circle()
                        .stroke(Color.blue.opacity(0.3), lineWidth: 2)
                        .scaleEffect(pulseAnimation ? 1.5 : 1.0)
                        .opacity(pulseAnimation ? 0 : 1)
                )
                .onAppear {
                    withAnimation(
                        .easeInOut(duration: 1.0)
                        .repeatForever(autoreverses: false)
                    ) {
                        pulseAnimation = true
                    }
                }
        }
    }

    private var processingText: some View {
        Text("Processing...")
            .font(.system(size: 13, weight: .medium))
            .foregroundColor(.white.opacity(0.9))
    }

    private var backgroundView: some View {
        RoundedRectangle(cornerRadius: 26)
            .fill(Color.black.opacity(0.85))
            .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 4)
            .overlay(
                RoundedRectangle(cornerRadius: 26)
                    .strokeBorder(Color.white.opacity(0.1), lineWidth: 1)
            )
    }

    @State private var pulseAnimation = false
}

#Preview("Recording") {
    RecordingOverlayView(
        isRecording: true,
        isProcessing: false,
        audioLevel: 0.6
    )
    .frame(width: 240, height: 52)
    .padding(40)
    .background(Color.gray.opacity(0.3))
}

#Preview("Processing") {
    RecordingOverlayView(
        isRecording: false,
        isProcessing: true,
        audioLevel: 0.0
    )
    .frame(width: 240, height: 52)
    .padding(40)
    .background(Color.gray.opacity(0.3))
}
