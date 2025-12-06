//
//  PlayerScoreReview.swift
//  MiniMate
//
//  Created by Garrett Butchko on 6/10/25.
//

// ScoreCardView.swift
// MiniMate
//
// Refactored to use SwiftData models and AuthViewModel

import SwiftUI

struct PlayerScoreReview: View {
    let player: PlayerDTO
    let course: Course
    
    @State private var scrollOffset: CGFloat = 0
    @State private var uuid: UUID? = nil
    
    var body: some View {
        VStack {
            headerView
            scoreGridView
        }
        .padding()
    }
    
    // MARK: Header
    private var headerView: some View {
        VStack{
            
            Capsule()
                .frame(width: 38, height: 6)
                .foregroundColor(.gray)
            HStack {
                Text(player.name + "'s Scorecard")
                    .font(.title).fontWeight(.bold)
                Spacer()
            }
        }
    }
    
    // MARK: Score Grid
    private var scoreGridView: some View {
        VStack {
            
            playerHeaderRow
            Divider()
            scoreRows
            Divider()
            totalRow
        }
        .background(
            course.scoreCardColor
        )
        .clipShape(RoundedRectangle(cornerRadius: 25))
        .padding(.vertical)
    }
    
    /// Player Row
    private var playerHeaderRow: some View {
        HStack {
            Text("Name")
                .frame(width: 100, height: 60)
                .font(.title3).fontWeight(.semibold)
            Divider()
            
            Spacer()
            PhotoIconView(photoURL: player.photoURL, name: player.name, imageSize: 30, background: .ultraThinMaterial)
                .frame(width: 100, height: 60)
            Spacer()
        }
        .frame(height: 60)
        .padding(.top)
    }
    
    /// Score columns and hole icons
    private var scoreRows: some View {
        ScrollView {
            HStack(alignment: .top) {
                holeNumbersColumn
                Divider()
                PlayerScoreColumnShowViewDTO(player: player)
            }
        }
    }
    
    /// first column with holes and number i.e "hole 1"
    private var holeNumbersColumn: some View {
        VStack {
            ForEach(1...player.holes.count, id: \.self) { i in
                if i != 1 { Divider() }
                VStack{
                    Text("Hole \(i)")
                        .font(.body).fontWeight(.medium)
                    if let pars = course.pars {
                        Text("Par: \(pars[i - 1])")
                            .font(.caption)
                    }
                }
                .frame(height: 60)
            }
        }
        .frame(width: 100)
    }
    
    /// totals row
    private var totalRow: some View {
        HStack {
            VStack{
                Text("Total")
                    .font(.title3).fontWeight(.semibold)
                
                if let coursePars = course.pars {
                    Text("Par: \(coursePars.compactMap { $0 }.reduce(0, +))")
                        .font(.caption)
                }
            }
            .frame(width: 100, height: 60)
            Divider()
                HStack {
                    Spacer()
                    Text("Total: \(player.totalStrokes)")
                        .frame(width: 100, height: 60)
                    Spacer()
                }
        }
        .frame(height: 60)
        .padding(.bottom)
    }
}

struct PlayerScoreColumnShowViewDTO: View {
    var player: PlayerDTO
    
    var body: some View {
        VStack {
            ForEach(player.holes.sorted(by: { $0.number < $1.number }), id: \.number) { hole in
                HoleRowShowViewDTO(hole: hole)
            }
        }
    }
}

// MARK: - HoleRowView
struct HoleRowShowViewDTO: View {
    var hole: HoleDTO
    
    var body: some View {
        VStack {
            if hole.number != 1 { Divider() }
            HStack{
                Spacer()
                Text("\(hole.strokes)")
                    .frame(height: 60)
                Spacer()
            }
        }
    }
}
