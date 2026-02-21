//
//  ConfirmationDialog.swift
//  Swift Cleaner
//
//  Created by APPLE on 12/2/2026.
//


import SwiftUI

struct ConfirmationDialog: ViewModifier {
    @Binding var isPresented: Bool
    let title: String
    let message: String
    let icon: String
    let destructiveAction: () -> Void
    
    func body(content: Content) -> some View {
        content
            .alert(title, isPresented: $isPresented) {
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) {
                    destructiveAction()
                }
            } message: {
                Label(message, systemImage: icon)
            }
    }
}

extension View {
    func confirmationDialog(
        isPresented: Binding<Bool>,
        title: String,
        message: String,
        icon: String = "exclamationmark.triangle",
        destructiveAction: @escaping () -> Void
    ) -> some View {
        modifier(ConfirmationDialog(
            isPresented: isPresented,
            title: title,
            message: message,
            icon: icon,
            destructiveAction: destructiveAction
        ))
    }
}