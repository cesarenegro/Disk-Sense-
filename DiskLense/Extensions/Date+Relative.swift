//
//  Date+Relative.swift
//  Swift Cleaner
//
//  Created by APPLE on 12/2/2026.
//

import Foundation

extension Date {
    var relativeFormatted: String {
        #if RELEASE_SCREENSHOT
        return ScreenshotMode.formattedDate(self)
        #else
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: self, relativeTo: Date())
        #endif
    }
    
    var shortFormatted: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: self)
    }
    
    var dayOnly: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: self)
    }
}
