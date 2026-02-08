//
//  RecapView.swift
//  MiniMate
//
//  Created by Garrett Butchko on 5/12/25.
//
import SwiftUI
import ConfettiSwiftUI

struct RecapView<Content: View>: View {
    @Environment(\.modelContext) private var context
    @EnvironmentObject var viewManager: ViewManager
    
    @State var confettiTrigger: Bool = false
    @State var showReviewSheet: Bool = false
    @State var showLeaderBoardAlert: Bool = false
    
    @State var email: String = ""
    
    let course: Course?
    
    let game: Game?
    
    var isGuest: Bool
    
    var sortedPlayers: [Player] {
        guard let game = game else { return [] }

        let players = game.players.sorted { $0.totalStrokes < $1.totalStrokes }
        return players.isEmpty ? [] : players
    }
    
    @State var gameReview: Game? = nil
    
    let content: () -> Content
    
    var body: some View {
        GeometryReader{ geometry in
            ZStack{
                Rectangle()
                    .fill(.ultraThinMaterial)
                    .ignoresSafeArea()
                
                VStack(spacing: 10){
                    Spacer()
                    VStack{
                        Text("Review of Game")
                            .font(.subheadline)
                            .opacity(0.5)
                        Text("Congratulations!")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                    }
                    
                    Spacer()
                    
                    if sortedPlayers.count > 1 {
                        
                        PlayerStandingView(player: sortedPlayers[0], place: .first, course: course, onlyPlayer: false)
                        
                        HStack{
                            PlayerStandingView(player: sortedPlayers[1], place: .second, course: course, onlyPlayer: false)
                            if sortedPlayers.count > 2{
                                PlayerStandingView(player: sortedPlayers[2], place: .third, course: course, onlyPlayer: false)
                            }
                        }
                        
                        if sortedPlayers.count > 3 {
                            ScrollView{
                                ForEach(sortedPlayers[3...]) { player in
                                    PlayerStandingView(player: player, place: nil, course: course, onlyPlayer: false)
                                }
                            }
                            .frame(height: geometry.size.height * 0.3)
                        }
                        
                        
                    } else {
                        PlayerStandingView(player: sortedPlayers[0], place: .first, course: course, onlyPlayer: true)
                    }
                    
                    if sortedPlayers.count <= 3 {
                        Spacer()
                        Spacer()
                    }
                    
                    Button {
                        gameReview = game
                    } label: {
                        Label("Review Game", systemImage: "chart.bar.xaxis")
                            .font(.headline)
                            .padding(.horizontal, 18)
                            .padding(.vertical, 10)
                            .foregroundStyle(.blue)
                    }
                    .background {
                        Capsule()
                            .fill(.ultraThinMaterial)
                            .overlay(
                                Capsule()
                                    .stroke(.blue.opacity(0.6), lineWidth: 1)
                            )
                    }
                    .sheet(item: $gameReview){
                        gameReview = nil
                    } content: { game in
                        GameReviewView(game: game, gameReview: $gameReview)
                            .presentationDragIndicator(.visible)
                    }
                    content()
                }
                .confettiCannon(trigger: $confettiTrigger, num: 40, confettis: [.shape(.slimRectangle)])
                .onAppear {
                    confettiTrigger = true
                }
                .padding()
            }
            .padding(.bottom)
        }
    }
}

enum PlayerStanding: Equatable {
    case first
    case second
    case third
}

struct PlayerStandingView: View {
    let player: Player
    let place: PlayerStanding?
    let course: Course?
    let onlyPlayer: Bool

    var color: Color {
        switch place {
        case .first:
            Color.yellow
        case .second:
            Color.gray
        case .third:
            Color.brown
        default:
            Color.clear
        }
    }
    
    var moji: String {
        switch place {
        case .first:
            "🥇"
        case .second:
            "🥈"
        case .third:
            "🥉"
        default:
            ""
        }
    }
    
    var imageSize: CGFloat {
        switch place {
        case .first:
            70
        case .second:
            40
        case .third:
            40
        default:
            30
        }
    }
    
    var body: some View {
        
        VStack{
            HStack{
                if place != nil {
                    if onlyPlayer {
                        PhotoIconView(photoURL: player.photoURL, name: player.name, imageSize: 70, background: .ultraThinMaterial)
                    } else {
                        PhotoIconView(photoURL: player.photoURL, name: player.name + moji, imageSize: imageSize, background: color)
                    }
                } else {
                    PhotoIconView(photoURL: player.photoURL, name: player.name, imageSize: imageSize, background: .ultraThinMaterial)
                }
                
                Spacer()
                
                Text(player.totalStrokes.description)
                    .font(.title)
                    .padding()
            }
            AddToLeaderBoardButton(course: course, player: player)
        }
        .padding()
        .background {
            if place != nil {
                if onlyPlayer {
                    RoundedRectangle(cornerRadius: 25)
                        .fill(.ultraThinMaterial)
                        .overlay(
                            RoundedRectangle(cornerRadius: 25)
                                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                        )
                } else {
                    RoundedRectangle(cornerRadius: 25)
                        .fill(color)
                        .opacity(0.2)
                }
            } else {
                RoundedRectangle(cornerRadius: 25)
                    .fill(.ultraThinMaterial)
            }
        }
    }
}

