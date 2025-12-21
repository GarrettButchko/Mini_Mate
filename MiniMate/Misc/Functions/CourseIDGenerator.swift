//
//  CourseIDGenerator.swift
//  MiniMate
//
//  Created by Garrett Butchko on 11/30/25.
//

import Foundation
import CryptoKit

final class CourseIDGenerator {

    // MARK: - Public API
    static func generateCourseID(from item: MapItemDTO) -> String {
        let namePart = slugify(item.name ?? "unknown")
        
        let hashInput = "\(item.coordinate.latitude)-\(item.coordinate.longitude)-\(item.name ?? "")"
        let hash = shortHash(hashInput)

        return "\(namePart)-\(hash)"
    }

    // MARK: - Private Helpers
    private static func slugify(_ text: String) -> String {
        let lower = text.lowercased()
        let trimmed = lower.trimmingCharacters(in: .whitespacesAndNewlines)

        let allowed = trimmed
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { !$0.isEmpty }
            .joined(separator: "-")

        return allowed
    }

    private static func shortHash(_ text: String) -> String {
        let digest = SHA256.hash(data: text.data(using: .utf8)!)
        return digest
            .map { String(format: "%02x", $0) }
            .joined()
            .prefix(8)
            .lowercased()
    }
}
