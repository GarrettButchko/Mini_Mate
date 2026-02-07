//
//  GameInfoReviewView.swift
//  MiniMate
//
//  Created by Garrett Butchko on 4/28/25.
//


import SwiftUI

/// Displays and allows editing of the current user's profile
struct GameInfoView: View {
    var game: Game
    @Binding var isSheetPresent: Bool

    var body: some View {
        ZStack {
            VStack {
                // Header and drag indicator
                Capsule()
                    .frame(width: 38, height: 6)
                    .foregroundColor(.gray)
                    .padding(10)

                HStack {
                    Text("Game Info")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                        .padding(.leading, 30)
                    Spacer()
                }

                List {
                    Section ("Info") {
                        UserInfoRow(label: "Game ID/Code", value: game.id)
                        UserInfoRow(label: "Number of players", value: "\(game.players.count)")
                        UserInfoRow(label: "Number of holes", value: "\(game.numberOfHoles)")
                        UserInfoRow(label: "Date Started", value: game.date.formatted(date: .abbreviated, time: .omitted))
                        UserInfoRow(label: "Course ID", value: game.courseID ?? "No Course ID")
                    }
                }
            }
        }
    }
}
