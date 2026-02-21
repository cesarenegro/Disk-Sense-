//
//  LargeFile.swift
//  Swift Cleaner
//
//  Created by APPLE on 14/2/2026.
//


import Foundation

struct LargeFile: Identifiable, Hashable {
    let id: UUID
    let url: URL
    let size: Int64

    init(id: UUID = UUID(), url: URL, size: Int64) {
        self.id = id
        self.url = url
        self.size = size
    }
}
