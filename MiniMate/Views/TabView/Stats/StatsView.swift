//
//  StatsView.swift
//  MiniMate
//
//  Created by Garrett Butchko on 2/6/25.
//

import SwiftUI
import Charts
import MarqueeText
import _SwiftData_SwiftUI

struct StatsView: View {
    
    @Environment(\.modelContext) private var context
    @StateObject private var viewModel = StatsViewModel()
    
    @Query var allGames: [Game]
    
    var usersGames: [Game] {
        allGames.filter { authModel.userModel?.gameIDs.contains($0.id) == true }
    }
    
    var games: [Game] {
        let filteredGames: [Game]
        if viewModel.searchText.isEmpty {
            filteredGames = usersGames
        } else {
            filteredGames = usersGames.filter { $0.date.formatted(date: .abbreviated, time: .shortened).lowercased().contains(viewModel.searchText.lowercased()) }
        }
        
        let sortedGames: [Game]
        if viewModel.latest {
            sortedGames = filteredGames.sorted { $0.date > $1.date }
        } else {
            sortedGames = filteredGames.sorted { $0.date < $1.date }
        }
        
        return sortedGames
    }
    
    @StateObject var viewManager: ViewManager
    @StateObject var authModel: AuthViewModel
    
    @State private var isDismissed = false
    
    private var uniGameRepo: UnifiedGameRepository { UnifiedGameRepository(context: context) }
    
    @State var isRotating: Bool = false
    
    var body: some View {
        if (authModel.userModel != nil) {
            VStack{
                HStack {
                    ZStack {
                        if viewModel.pickedSection == "Games" {
                            Text("Game Stats")
                                .font(.title).fontWeight(.bold)
                                .transition(.opacity.combined(with: .scale))
                        } else {
                            Text("Overview")
                                .font(.title).fontWeight(.bold)
                                .transition(.opacity.combined(with: .scale))
                        }
                    }
                    .animation(.easeInOut(duration: 0.35), value: viewModel.pickedSection)
                    
                    Spacer()
                }
                
                Picker("Section", selection: $viewModel.pickedSection) {
                    ForEach(viewModel.pickerSections, id: \.self) {
                        Text($0)
                    }
                }
                .pickerStyle(.segmented)
                
                
                ZStack {
                    if viewModel.pickedSection == "Games" {
                        gamesSection
                            .transition(.asymmetric(
                                insertion: .move(edge: .leading).combined(with: .opacity),
                                removal: .move(edge: .leading).combined(with: .opacity)
                            ))
                    } else {
                        
                        if viewModel.analyzer?.hasGames == true {
                            overViewSection
                                .transition(.asymmetric(
                                    insertion: .move(edge: .trailing).combined(with: .opacity),
                                    removal: .move(edge: .trailing).combined(with: .opacity)
                                ))
                                .onAppear {
                                    viewModel.editOn = false
                                }
                        } else {
                            ScrollView{
                                Image("logoOpp")
                                    .resizable()
                                    .frame(width: 50, height: 50)
                                    .padding()
                            }
                            .onAppear {
                                viewModel.editOn = false
                            }
                        }
                        
                    }
                }
                .animation(.easeInOut(duration: 0.3), value: viewModel.pickedSection)
            }
            .padding([.top, .horizontal])
            .sheet(isPresented: $viewModel.isSharePresented) {
                ActivityView(activityItems: [viewModel.shareContent])
            }
            .onAppear{
                viewModel.onAppear(user: authModel.userModel!, games: games, context: context)
            }
        }
    }
    
    
    
    private var gamesSection: some View {
        ZStack{
            ScrollView {
                
                Rectangle()
                    .frame(height: 75)
                    .foregroundStyle(Color.clear)
                
                VStack (spacing: 15){
                    if NetworkChecker.shared.isConnected && !authModel.userModel!.isPro {
                        VStack{
                            BannerAdView(adUnitID: "ca-app-pub-8261962597301587/6344452429") // Replace with real one later
                                .frame(height: 50)
                                .padding()
                        }
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 25))
                    }
                    
                    if !authModel.userModel!.isPro && authModel.userModel!.gameIDs.count >= 2 {
                        Text("You’ve reached the free limit. Upgrade to Pro to store more than 2 games.")
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(.ultraThinMaterial)
                            .clipShape(RoundedRectangle(cornerRadius: 25))
                    }
                    
                    if !authModel.userModel!.gameIDs.isEmpty {
                        if !viewModel.isRefreshing {
                            ForEach(games) { game in
                                GameRow(context: _context, editOn: $viewModel.editOn, editingGameID: $viewModel.editingGameID, authModel: authModel, game: game, viewManager: viewManager, presentShareSheet: viewModel.presentShareSheet)
                                    .transition(.opacity)
                            }
                        } else {
                            ProgressView()
                        }
                    } else {
                        Image("logoOpp")
                            .resizable()
                            .frame(width: 50, height: 50)
                            .padding()
                    }
                    
                    Rectangle()
                        .frame(height: 1)
                        .foregroundStyle(Color.clear)
                }
            }
            
            
            VStack{
                HStack{
                    SearchBarView(searchText: $viewModel.searchText)
                    .padding(.vertical)
                    
                    Button {
                        viewModel.toggleSortWithCooldown()
                    } label: {
                        
                        ZStack{
                            
                            Circle()
                                .ifAvailableGlassEffect()
                                .frame(width: 50, height: 50)
                            
                            
                            if viewModel.latest{
                                Image(systemName: "arrow.up")
                                    .transition(.scale)
                                    .frame(width: 60, height: 60)
                            } else {
                                Image(systemName: "arrow.down")
                                    .transition(.scale)
                                    .frame(width: 60, height: 60)
                            }
                        }
                    }
                    Button(action: {
                        withAnimation(){
                            
                            isRotating = true
                            
                            viewModel.refreshFromCloudIfNeeded(user: authModel.userModel!, authModel: authModel, context: context) {
                                isRotating = false
                            }
                        }
                    }) {
                        Image(systemName: "arrow.trianglehead.2.clockwise")
                            .rotationEffect(.degrees(isRotating ? 360 : 0))
                            .font(.title2)
                            .foregroundColor(.blue)
                            .background(){
                                Circle()
                                    .ifAvailableGlassEffect()
                                    .frame(width: 50, height: 50)
                            }
                    }
                    .buttonStyle(.plain)
                    .transition(.move(edge: .trailing).combined(with: .opacity))
                    .padding(.horizontal, 10)
                }
                Spacer()
            }
        }
    }
    
    private var overViewSection: some View {
        ScrollView {
            if let analyzer = viewModel.analyzer {
                SectionStatsView(title: "Basic Stats") {
                    HStack{
                        StatCard(title: "Games Played", value: "\(analyzer.totalGamesPlayed)", color: .blue)
                        StatCard(title: "Players Faced", value: "\(analyzer.totalPlayersFaced)", color: .green)
                        StatCard(title: "Holes Played", value: "\(analyzer.totalHolesPlayed)", color: .blue)
                    }
                    HStack{
                        StatCard(title: "Average Strokes per Game", value: String(format: "%.1f", analyzer.averageStrokesPerGame), color: .blue)
                        StatCard(title: "Average Strokes per Hole", value: String(format: "%.1f", analyzer.averageStrokesPerHole), color: .green)
                    }
                }
                .padding(.top)
                
                if NetworkChecker.shared.isConnected && !authModel.userModel!.isPro {
                    VStack{
                        BannerAdView(adUnitID: "ca-app-pub-8261962597301587/6344452429") // Replace with real one later
                            .frame(height: 50)
                            .padding()
                    }
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 25))
                    .padding(.top)
                }
                
                SectionStatsView(title: "Average 18 Hole Game"){
                    BarChartView(data: analyzer.averageHoles18, title: "Average Strokes")
                }
                .padding(.top)
                SectionStatsView(title: "Misc Stats") {
                    HStack{
                        StatCard(title: "Best Game", value: "\(analyzer.bestGameStrokes ?? 0)", color: .blue)
                        StatCard(title: "Worst Game", value: "\(analyzer.worstGameStrokes ?? 0)", color: .green)
                        StatCard(title: "Hole in One's", value: "\(analyzer.holeInOneCount)", color: .blue)
                    }
                }
                .padding(.top)
                SectionStatsView(title: "Average 9 Hole Game"){
                    BarChartView(data: analyzer.averageHoles9, title: "Average Strokes")
                }
                .padding(.vertical)
            } else {
                // Placeholder while analyzer initializes
                Image("logoOpp")
                    .resizable()
                    .frame(width: 50, height: 50)
                    .padding()
            }
        }
    }
}




struct GameGridView: View {
    @Binding var editOn: Bool
    @StateObject var authModel: AuthViewModel
    @Environment(\.modelContext) private var context
    var game: Game
    var sortedPlayers: [Player] {
        game.players.sorted(by: { $0.totalStrokes < $1.totalStrokes })
    }
    
    // FIXED: Bracket mismatch in GameGridView.body
    var body: some View {
        VStack(alignment: .leading, spacing: 16) { // Adds vertical spacing
            // Game Info & Players Row
            HStack(alignment: .top, spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    
                    if let gameLocName = game.location?.name{
                        MarqueeText(
                            text: gameLocName,
                            font: UIFont.preferredFont(forTextStyle: .title3),
                            leftFade: 16,
                            rightFade: 16,
                            startDelay: 2 // recommend 1–2 seconds for a subtle Apple-like pause
                        )
                        .foregroundStyle(.mainOpp)
                        .font(.title3).fontWeight(.bold)
                    } else {
                        MarqueeText(
                            text: game.date.formatted(date: .abbreviated, time: .shortened),
                            font: UIFont.preferredFont(forTextStyle: .title3),
                            leftFade: 16,
                            rightFade: 16,
                            startDelay: 2 // recommend 1–2 seconds for a subtle Apple-like pause
                        )
                        .foregroundStyle(.mainOpp)
                        .font(.title3).fontWeight(.bold)
                    }
                    
                    
                    Text("Number of Holes: \(game.numberOfHoles)")
                        .font(.caption).foregroundColor(.secondary)
                }
                
                
                if game.players.count > 1 {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) { // Player icon spacing
                            ForEach(game.players) { player in
                                if game.players.count != 0{
                                    if player.id != game.players[0].id {
                                        Divider()
                                            .frame(height: 50)
                                    }
                                }
                                
                                if sortedPlayers[0] == player {
                                    PhotoIconView(photoURL: player.photoURL, name: player.name + "🥇", imageSize: 20, background: Color.yellow)
                                } else {
                                    PhotoIconView(photoURL: player.photoURL, name: player.name, imageSize: 20, background: .ultraThinMaterial)
                                }
                                
                            }
                        }
                    }
                    .frame(height: 50)
                } else {
                    if sortedPlayers.count != 0 {
                        PhotoIconView(photoURL: sortedPlayers[0].photoURL, name: sortedPlayers[0].name, imageSize: 20, background: .ultraThinMaterial)
                    }
                }
                
            }
            
            // Bar Chart
            BarChartView(data: averageStrokes(), title: "Average Strokes")
            
            
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 25))
    }
    
    
    
    
    /// Returns one Hole per hole-number, whose `strokes` is the integer average
    /// across all players for that hole.
    func averageStrokes() -> [Hole] {
        let holeCount   = game.numberOfHoles
        let playerCount = game.players.count
        guard playerCount > 0 else { return [] }
        
        // 1) Sum strokes per hole index (0-based)
        var sums = [Int](repeating: 0, count: holeCount)
        for player in game.players {
            for hole in player.holes {
                let idx = hole.number - 1
                sums[idx] += hole.strokes
            }
        }
        
        // 2) Build averaged Hole objects
        return sums.enumerated().map { (idx, total) in
            let avg = total / playerCount
            return Hole(number: idx + 1, strokes: avg)
        }
    }
}

struct GameRow: View {
    @Environment(\.modelContext) var context
    
    @Binding var editOn: Bool
    @Binding var editingGameID: String?
    @StateObject var authModel: AuthViewModel
    
    var game: Game
    
    var viewManager: ViewManager
    var presentShareSheet: (String) -> Void
    
    var localGameRepo: LocalGameRepository { LocalGameRepository(context: context) }
    var remoteGameRepo = FirestoreGameRepository()
    
    var body: some View {
        GeometryReader { proxy in
            HStack{
                GameGridView(editOn: $editOn, authModel: authModel, game: game)
                    .frame(width: proxy.size.width)
                    .transition(.opacity)
                    .swipeMod(
                        editingID: $editingGameID,
                        id: game.id,
                        buttonPressFunction: {
                            viewManager.navigateToGameReview(game)
                        },
                        buttonOne:
                        NetworkChecker.shared.isConnected ?
                        ButtonSkim(color: Color.blue, systemImage: "square.and.arrow.up", string: makeShareableSummary(for: game)) :
                        nil
                    ) {
                        if let user = authModel.userModel {
                            withAnimation {
                                user.gameIDs.removeAll(where: { $0 == game.id })
                            }
                            UserRepository().saveRemote(id: authModel.currentUserIdentifier!, userModel: user) { _ in }
                                // Delete the SwiftData object *after* a delay
                            remoteGameRepo.delete(id: game.id) { _ in }
                            
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                localGameRepo.delete(id: game.id) { _ in }
                            }
                        }
                    }
            }
        }
        .frame(height: 198)
    }
    
    /// Build a plain-text summary (you could also return a URL to a generated PDF/image)
    func makeShareableSummary(for game: Game) -> String {
        var lines = ["MiniMate Scorecard",
                     "Date: \(game.date.formatted(.dateTime))",
                     ""]
        
        for player in game.players {
            var holeLine = ""
            
            for hole in player.holes {
                holeLine += "|\(hole.strokes)"
            }
            
            lines.append("\(player.name): \(player.totalStrokes) strokes (\(player.totalStrokes))")
            lines.append("Holes " + holeLine)
            
        }
        lines.append("")
        lines.append("Download MiniMate: https://apps.apple.com/app/id6745438125")
        return lines.joined(separator: "\n")
    }
}

struct ActivityView: UIViewControllerRepresentable {
    var activityItems: [Any]
    var applicationActivities: [UIActivity]? = nil
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems,
                                 applicationActivities: applicationActivities)
    }
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

