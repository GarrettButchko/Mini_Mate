//
//  PlayerDTO.swift
//  MiniMate
//
//  Created by Garrett Butchko on 12/19/25.
//
import Foundation

struct PlayerDTO: Codable, Identifiable, Equatable {
    var id: String
    var userId: String
    var name: String
    var photoURL: URL?
    var totalStrokes: Int
    var inGame: Bool
    var holes: [HoleDTO]
    var email: String?
}
