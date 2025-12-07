// GameReviewView.swift
// MiniMate
//
// Refactored to use SwiftData models and AuthViewModel

import SwiftUI

struct GameReviewView: View {
    @ObservedObject var viewManager: ViewManager
    @StateObject private var viewModel: GameReviewViewModel
    
    var showBackToStatsButton: Bool = false
    var isInCourseSettings: Bool = false
    
    @State private var scrollOffset: CGFloat
    @State private var uuid: UUID?
    @State private var showInfoView: Bool
    
    // Custom init to assign @StateObject and normal vars
    init(viewManager: ViewManager, game: Game, showBackToStatsButton: Bool = false, isInCourseSettings: Bool = false, scrollOffset: CGFloat = 0, uuid: UUID? = nil, showInfoView: Bool = false) {
        self.showBackToStatsButton = showBackToStatsButton
        self.isInCourseSettings = isInCourseSettings
        
        _viewModel = StateObject(wrappedValue: GameReviewViewModel(game: game))
        
        _viewManager = ObservedObject(wrappedValue: viewManager)
        _scrollOffset = State(initialValue: scrollOffset)
        _uuid = State(initialValue: uuid)
        _showInfoView = State(initialValue: showInfoView)
    }
    
    var body: some View {
        VStack {
            headerView
            scoreGridView
            footerView
        }
        .padding()
        .sheet(isPresented: $showInfoView) {
            GameInfoView(game: viewModel.game, isSheetPresent: $showInfoView)
        }
    }
    
    // MARK: Header
    private var headerView: some View {
        VStack{
            if !showBackToStatsButton{
                Capsule()
                    .frame(width: 38, height: 6)
                    .foregroundColor(.gray)
            }
            HStack {
                VStack(alignment: .leading){
                    Text("Scorecard")
                        .font(.title).fontWeight(.bold)
                    if let locationName = viewModel.course?.name {
                        Text(locationName)
                            .font(.subheadline)
                    }
                }
                Spacer()
                Button {
                    showInfoView = true
                } label: {
                    Image(systemName: "info.circle")
                        .resizable()
                        .frame(width: 20, height: 20)
                }
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
        .onAppear {
            viewModel.loadCourse()
        }
        .background {
            scoreCardBackground
        }
        .clipShape(RoundedRectangle(cornerRadius: 25))
        .padding(.vertical)
    }
    
    private var scoreCardBackground: some View {
        Group {
            if let color = viewModel.course?.scoreCardColor {
                Rectangle().fill(color)
            } else {
                Rectangle().fill(.ultraThinMaterial)
            }
        }
    }
    
    /// Player Row
    private var playerHeaderRow: some View {
        HStack {
            Text("Name")
                .frame(width: 100, height: 60)
                .font(.title3).fontWeight(.semibold)
            Divider()
            SyncedScrollViewRepresentable(scrollOffset: $scrollOffset, syncSourceID: $uuid) {
                HStack {
                    ForEach(viewModel.game.players, id: \.self) { player in
                        if player.id != viewModel.game.players[0].id { Divider() }
                        PhotoIconView(photoURL: player.photoURL, name: player.name, imageSize: 30, background: .ultraThinMaterial)
                            .frame(width: 100, height: 60)
                    }
                }
            }
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
                SyncedScrollViewRepresentable(scrollOffset: $scrollOffset, syncSourceID: $uuid) {
                    PlayerColumnsShowView(game: viewModel.game)
                }
            }
        }
    }
    
    /// first column with holes and number i.e "hole 1"
    private var holeNumbersColumn: some View {
        VStack {
            ForEach(1...viewModel.holeCount, id: \.self) { i in
                if i != 1 { Divider() }
                VStack {
                    Text("Hole \(i)")
                        .font(.body).fontWeight(.medium)

                    if let pars = viewModel.course?.pars, pars.indices.contains(i - 1) {
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
                if let course = viewModel.course, let coursePars = course.pars{
                    Text("Par: \(coursePars.reduce(0) { $0 + ($1) })")
                        .font(.caption)
                }
            }
            .frame(width: 100, height: 60)
            Divider()
            SyncedScrollViewRepresentable(scrollOffset: $scrollOffset, syncSourceID: $uuid) {
                HStack {
                    ForEach(viewModel.game.players) { player in
                        if player.id != viewModel.game.players[0].id { Divider() }
                        Text("Total: \(player.totalStrokes)")
                            .frame(width: 100, height: 60)
                    }
                }
            }
        }
        .frame(height: 60)
        .padding(.bottom)
    }
    
    // MARK: Footer complete game button and timer
    private var footerView: some View {
        
        VStack{
            ZStack{
                HStack{
                    if showBackToStatsButton {
                        Spacer()
                    }
                    if NetworkChecker.shared.isConnected {
                        ShareLink(item: viewModel.shareText){
                            Image(systemName: "square.and.arrow.up")
                                .font(.title2)
                        }
                        .padding()
                    }
                }
                if showBackToStatsButton {
                    HStack {
                        Button {
                            if !isInCourseSettings {
                                viewManager.navigateToMain(0)
                            }
                        } label: {
                            ZStack {
                                RoundedRectangle(cornerRadius: 25)
                                    .fill(Color.blue)
                                    .frame(width: 200, height: 60)
                                Text("Back to Stats")
                                    .foregroundColor(.white).fontWeight(.bold)
                            }
                        }
                    }
                }
            }
            
            if isInCourseSettings {
                if let course = viewModel.course, course.customAdActive {
                    Button {
                        if let link = course.adLink, link != "" {
                            if let url = URL(string: link) {
                                UIApplication.shared.open(url)
                            }
                        }
                    } label: {
                        HStack{
                            VStack(alignment: .leading, spacing: 8) {
                                
                                if let adTitle = course.adTitle {
                                    Text(adTitle)
                                        .foregroundStyle(.mainOpp)
                                        .font(.headline)
                                        .fontWeight(.semibold)
                                }
                                
                                if let adDescription = course.adDescription {
                                    Text(adDescription)
                                        .foregroundStyle(.mainOpp)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                        .multilineTextAlignment(.leading)
                                        .padding(.trailing)
                                }
                            }
                            Spacer()
                            if let adImage = course.adImage, adImage != ""  {
                                AsyncImage(url: URL(string: adImage)) { phase in
                                    switch phase {
                                    case .empty:
                                        ProgressView()
                                            .frame(height: 60)
                                    case .success(let image):
                                        image
                                            .resizable()
                                            .scaledToFill()
                                            .frame(height: 60)
                                            .clipShape(RoundedRectangle(cornerRadius: 12))
                                            .clipped()
                                    case .failure:
                                        Image(systemName: "photo")
                                            .resizable()
                                            .scaledToFit()
                                            .frame(height: 60)
                                            .foregroundColor(.gray)
                                            .background(Color.gray.opacity(0.2))
                                            .clipShape(RoundedRectangle(cornerRadius: 12))
                                    @unknown default:
                                        EmptyView()
                                    }
                                }
                            }
                            Spacer()
                        }
                        .padding()
                    }
                } else if let course = viewModel.course, !course.customAdActive{
                    BannerAdView(adUnitID: "ca-app-pub-8261962597301587/6716977198") // Replace with real one later
                        .frame(height: 50)
                        .padding(.top, 5)
                }
            }
            
        }
        .padding(.bottom)
    }
}

// MARK: - PlayerScoreColumnView

struct PlayerScoreColumnShowView: View {
    var player: Player
    
    var body: some View {
        VStack {
            ForEach(player.holes.sorted(by: { $0.number < $1.number }), id: \.number) { hole in
                HoleRowShowView(hole: hole)
            }
        }
    }
}

// MARK: - HoleRowView
struct HoleRowShowView: View {
    var hole: Hole
    
    var body: some View {
        VStack {
            if hole.number != 1 { Divider() }
            Text("\(hole.strokes)")
                .frame(height: 60)
        }
    }
}

struct PlayerColumnsShowView: View {
    var game: Game
    
    var body: some View {
        HStack {
            ForEach(game.players) { player in
                if player.id != game.players[0].id{
                    Divider()
                }
                PlayerScoreColumnShowView( player: player)
                    .frame(width: 100)
            }
        }
    }
}

