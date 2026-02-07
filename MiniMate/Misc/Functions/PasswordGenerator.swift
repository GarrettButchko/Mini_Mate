//
//  PasswordGenerator.swift
//  MiniMate
//
//  Created by Garrett Butchko on 12/1/25.
//

import Foundation
import Security

public final class PasswordGenerator {

    public enum Style {
        case strong(length: Int = 20, useSymbols: Bool = true)
        case memorable(length: Int = 16, includeDigits: Bool = true)
    }

    // MARK: - Public API
    public static func generate(_ style: Style) -> String {
        switch style {
        case .strong(let length, let useSymbols):
            return generateStrong(length: length, useSymbols: useSymbols)
        case .memorable(let length, let includeDigits):
            return generateMemorable(length: length, includeDigits: includeDigits)
        }
    }

    // MARK: - Character Sets
    private static let uppercase = Array("ABCDEFGHIJKLMNOPQRSTUVWXYZ")
    private static let lowercase = Array("abcdefghijklmnopqrstuvwxyz")
    private static let digits    = Array("0123456789")
    private static let symbols   = Array("!@#$%&()[]{}")

    // MARK: - Strong Password
    private static func generateStrong(length: Int, useSymbols: Bool) -> String {
        let length = max(length, 4)

        var sets: [[Character]] = [
            uppercase,
            lowercase,
            digits
        ]
        if useSymbols { sets.append(symbols) }

        let pool = sets.flatMap { $0 }

        // Ensure at least one character from each chosen set
        var result: [Character] = sets.map { $0[randomIndex($0.count)] }

        // Fill the rest
        while result.count < length {
            result.append(pool[randomIndex(pool.count)])
        }

        // Shuffle with secure randomness
        for i in stride(from: result.count - 1, through: 1, by: -1) {
            let j = randomIndex(i + 1)
            if i != j { result.swapAt(i, j) }
        }

        return String(result)
    }

    // MARK: - Memorable Password
    private static func generateMemorable(length: Int, includeDigits: Bool) -> String {
        let length = max(length, 4)

        let consonants = Array("bcdfghjklmnpqrstvwxyz")
        let vowels = Array("aeiou")

        var output = ""
        var useConsonant = randomIndex(2) == 0

        while output.count < length {
            // Build a small syllable (1–2 chars)
            let syllableLength = randomIndex(2) + 1

            for _ in 0..<syllableLength {
                if output.count >= length { break }
                output.append(
                    useConsonant
                    ? consonants[randomIndex(consonants.count)]
                    : vowels[randomIndex(vowels.count)]
                )
                useConsonant.toggle()
            }

            // Occasional digit injection
            if includeDigits && output.count < length && randomIndex(8) == 0 {
                output.append(digits[randomIndex(digits.count)])
            }
        }

        // Trim to exact length
        if output.count > length {
            output = String(output.prefix(length))
        }

        return output
    }

    // MARK: - Secure Random
    private static func randomIndex(_ upperBound: Int) -> Int {
        precondition(upperBound > 0)

        // Secure modulo-free random
        var value: UInt32 = 0
        let result = SecRandomCopyBytes(kSecRandomDefault, 4, &value)
        precondition(result == errSecSuccess, "Secure RNG failed")

        return Int(value % UInt32(upperBound))
    }
}
