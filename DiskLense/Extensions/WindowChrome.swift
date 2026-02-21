//
//  WindowChrome.swift
//  Swift Cleaner
//
//  Created by APPLE on 13/2/2026.
//


import SwiftUI
import AppKit

struct WindowChrome: NSViewRepresentable {
    let cornerRadius: CGFloat

    func makeNSView(context: Context) -> NSView {
        let v = NSView()
        DispatchQueue.main.async { apply(to: v) }
        return v
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        DispatchQueue.main.async { apply(to: nsView) }
    }

    private func apply(to nsView: NSView) {
        guard let window = nsView.window else { return }

        window.titleVisibility = .hidden
        window.titlebarAppearsTransparent = true
        window.isMovableByWindowBackground = true

        // Transparent window background to let SwiftUI draw the rounded container
        window.isOpaque = false
        window.backgroundColor = .clear

        // Ensure layer-backed content for corner radius clipping
        if let contentView = window.contentView {
            contentView.wantsLayer = true
            contentView.layer?.cornerRadius = cornerRadius
            contentView.layer?.masksToBounds = true
        }
    }
}
