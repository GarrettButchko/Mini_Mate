//
//  Bundle-Decodable.swift
//  Pokedex
//
//  Created by Garrett Butchko on 10/18/24.
//

import Foundation

extension Bundle {
    func decode<T: Codable>(_ relativePath: String) -> T {
        // Locate the file using the relative path
        guard let url = self.url(forResource: relativePath, withExtension: nil) else {
            fatalError("Could not find \(relativePath) in bundle.")
        }
        
        // Load data from the file
        guard let data = try? Data(contentsOf: url) else {
            fatalError("Could not load \(relativePath) from bundle.")
        }
        
        // Decode the data
        let decoder = JSONDecoder()
        
        do {
            return try decoder.decode(T.self, from: data)
        } catch DecodingError.keyNotFound(let key, let context) {
            fatalError("Failed to decode \(relativePath) due to missing key '\(key.stringValue)' - \(context.debugDescription)")
        } catch DecodingError.typeMismatch(_, let context) {
            fatalError("Failed to decode \(relativePath) due to type mismatch - \(context.debugDescription)")
        } catch DecodingError.valueNotFound(let type, let context) {
            fatalError("Failed to decode \(relativePath) due to \(type) value not found - \(context.debugDescription)")
        } catch DecodingError.dataCorrupted(_) {
            fatalError("Failed to decode \(relativePath) due to data corruption")
        } catch {
            fatalError("Failed to decode \(relativePath) due to error: \(error.localizedDescription)")
        }
    }
}

extension URL {
    func fetchAndDecode<T: Codable>() async throws -> T {
        let (data, _) = try await URLSession.shared.data(from: self)
        let decoder = JSONDecoder()
        
        do {
            return try decoder.decode(T.self, from: data)
        } catch DecodingError.keyNotFound(let key, let context) {
            throw NSError(domain: "", code: 1, userInfo: ["message": "Missing key '\(key.stringValue)' - \(context.debugDescription)"])
        } catch DecodingError.typeMismatch(_, let context) {
            throw NSError(domain: "", code: 2, userInfo: ["message": "Type mismatch - \(context.debugDescription)"])
        } catch DecodingError.valueNotFound(let type, let context) {
            throw NSError(domain: "", code: 3, userInfo: ["message": "\(type) value not found - \(context.debugDescription)"])
        } catch DecodingError.dataCorrupted(let context) {
            throw NSError(domain: "", code: 4, userInfo: ["message": "Data corruption - \(context.debugDescription)"])
        } catch {
            throw NSError(domain: "", code: 5, userInfo: ["message": error.localizedDescription])
        }
    }
}


