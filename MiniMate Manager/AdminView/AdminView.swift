//
//  AdminView.swift
//  MiniMate
//
//  Created by Garrett Butchko on 6/9/25.
//

import SwiftUI
import FirebaseDatabase

struct AdminView: View {
    @Environment(\.modelContext) private var context
    
    @ObservedObject var viewManager: ViewManager
    @ObservedObject var authModel: AuthViewModel
    
    var body: some View {
        if let adminType = authModel.userModel?.adminType {
            if adminType == "CREATOR" {
                CreatorView(authModel: authModel)
            } else if adminType != "Unknown" {
                LocationView(authModel: authModel, id: adminType)
            }
        }
    }
}

struct CreatorView: View {
    
    @ObservedObject var authModel: AuthViewModel
    
    @State var searchText: String = ""
    @State var selectedCourse: SmallCourse? = nil
    @State var allCourses: [SmallCourse] = []
    
    let courseRepo = CourseRepository()
    
    var body: some View {
        VStack {
            VStack{
                HStack{
                    Text("Creator")
                        .font(.title).fontWeight(.bold)
                    Spacer()
                }
                ZStack {
                    
                    RoundedRectangle(cornerRadius: 25)
                        .fill(.sub) // Light background
                        .frame(height: 50)
                    
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundStyle(.secondary)
                        TextField("Search", text: $searchText)
                            .autocorrectionDisabled()
                            .textInputAutocapitalization(.never)
                            .padding(.trailing, 5)
                    }
                    .padding()
                }
            }
            .padding([.top, .horizontal])
            
            
            if !allCourses.isEmpty{
                List{
                    ForEach(allCourses) { smallCourse in
                        Button {
                            selectedCourse = smallCourse
                        } label: {
                            HStack{
                                Text(smallCourse.name)
                                    .foregroundStyle(.mainOpp)
                                Spacer()
                                Image(systemName: "arrow.forward")
                                    .foregroundStyle(.mainOpp)
                            }
                        }
                        .sheet(item: $selectedCourse) { item in
                            LocationView(authModel: authModel, id: item.id)
                        }
                    }
                }
            } else {
                Spacer()
                Text("Type a location to get started.")
                Spacer()
            }
            
        }
        .onChange(of: searchText) { _, newValue in
            if newValue != ""{
                courseRepo.fetchCourseIDs(prefix: newValue.lowercased()) { results in
                    self.allCourses = results
                }
            } else {
                allCourses = []
            }
        }
    }
}

struct LocationView: View {

    @ObservedObject var authModel: AuthViewModel
    
    @State private var listenerHandle: DatabaseHandle?
    
    @State var course: Course? = nil
    @State var courseLeaderboard: CourseLeaderboard? = nil
    
    @State var id: String
    
    @State var editOn: Bool = false
    @State var showSettings: Bool = false
    
    let courseLeaderBoardRepo = CourseLeaderboardRepository()
    let courseRepo = CourseRepository()
    
    @State private var isLoading = true
    
    var body: some View {
        VStack {
            if let course = course {
                VStack{
                    if let adminType = authModel.userModel?.adminType {
                        if adminType == "CREATOR" {
                            Capsule()
                                .frame(width: 38, height: 6)
                                .foregroundColor(.gray)
                        }
                    }
                    
                    HStack{
                        Text(course.name)
                            .font(.title).fontWeight(.bold)
                        Spacer()
                    }
                    
                    
                    if let courseTier = course.tier, courseTier >= 2{
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Leader Board")
                                    .font(.title3).fontWeight(.bold)
                                    .foregroundStyle(.mainOpp)
                                Spacer()
                                if let leaderboard = courseLeaderboard?.leaderBoard, leaderboard.count > 0{
                                    Button {
                                        withAnimation(){
                                            editOn.toggle()
                                        }
                                    } label: {
                                        if (courseLeaderboard?.leaderBoard) != nil{
                                            Text(editOn ? "Done" : "Edit")
                                                .transition(.move(edge: .trailing).combined(with: .opacity))
                                        }
                                    }
                                }
                            }
                            if let leaderboard = courseLeaderboard?.leaderBoard, let courseLeaderboard = courseLeaderboard, leaderboard.count > 0{
                                ScrollView{
                                    LeaderBoardList(players: leaderboard, course: course, courseLeaderboard: courseLeaderboard, courseLeaderboardRepo: courseLeaderBoardRepo, editOn: $editOn)
                                }
                            } else {
                                Text("No players in leader board yet.")
                                Spacer()
                            }
                        }
                        .padding()
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 25))
                        .padding(.bottom)
                    } else {
                        VStack{
                            Spacer()
                            Text("Upgrade to leaderboard tier to see a leaderboard.")
                            Spacer()
                        }
                    }
                    
                    Button {
                        showSettings = true
                    } label: {
                        HStack{
                            Spacer()
                            Image(systemName: "gearshape.fill")
                                .foregroundStyle(.white)
                            Text("Course Settings")
                                .foregroundStyle(.white)
                            Spacer()
                        }
                        .padding()
                        .background(.blue)
                        .clipShape(RoundedRectangle(cornerRadius: 25))
                    }
                    .sheet(isPresented: $showSettings) {
                        CourseSettingsView(authModel: authModel, course: course)
                    }
                }
                
            } else {
                ProgressView {
                    Text("Your course could not load please wait a moment and try again.")
                }
                
                Button {
                    isLoading = true
                    courseRepo.fetchCourse(id: id) { course in
                        if let course = course{
                            self.course = course
                        }
                        isLoading = false
                        print(id)
                    }
                } label: {
                    Text("Retry")
                }
                .padding()
            }
        }
        .padding()
        .onAppear {
            isLoading = true
            courseRepo.fetchCourse(id: id) { course in
                if let resolvedCourse = course {
                    self.course = resolvedCourse
                }
                isLoading = false   // <-- Immediately update UI
            }
            
            courseLeaderBoardRepo.fetchCourseLeaderboard(id: id) { courseLeaderboard in
                self.courseLeaderboard = courseLeaderboard
                courseLeaderBoardRepo.listenForCourseUpdates(id: id, listenerHandle: &listenerHandle) { courseLeaderboard in
                    self.courseLeaderboard = courseLeaderboard
                }
            }
        }
        .onDisappear {
            courseLeaderBoardRepo.stopListening(id: id, listenerHandle: &listenerHandle)
        }
    }
}

struct LeaderBoardList: View {
    @State private var localPlayers: [PlayerDTO]
    @State var selectedPlayer: PlayerDTO? = nil
    
    @Binding var editOn: Bool
    
    var courseLeaderboard: CourseLeaderboard
    var course: Course
    
    let courseLeaderboardRepo: CourseLeaderboardRepository
    
    init(players: [PlayerDTO], course: Course, courseLeaderboard: CourseLeaderboard, courseLeaderboardRepo: CourseLeaderboardRepository, editOn: Binding<Bool>) {
        self._editOn = editOn
        self.course = course
        self.courseLeaderboardRepo = courseLeaderboardRepo
        self.courseLeaderboard = courseLeaderboard
        self._localPlayers = State(initialValue: players)
    }
    
    var body: some View {
        ForEach(Array($localPlayers.enumerated()), id: \.element.id) { index, $player in
            if index != 0 {
                Divider()
            }
            HStack {
                Button {
                    selectedPlayer = player
                } label: {
                    if index == 0 {
                        Text("🥇")
                    } else if index == 1 {
                        Text("🥈")
                    } else if index == 2 {
                        Text("🥉")
                    }
                    Text("\(index + 1). \(player.name):")
                        .foregroundStyle(.mainOpp)
                    Spacer()
                    Text("\(player.totalStrokes)")
                        .foregroundStyle(.mainOpp)
                }
                .sheet(item: $selectedPlayer) { player in
                    PlayerScoreReview(player: player, course: course)
                }
                
                if editOn {
                    Button {
                        withAnimation{
                            _ = localPlayers.remove(at: index)
                        }
                        var leaderBoardCopy = courseLeaderboard
                        leaderBoardCopy.allPlayers = localPlayers
                        courseLeaderboardRepo.addOrUpdateCourseLeaderboard(leaderBoardCopy) { _ in }
                    } label: {
                        Image(systemName: "minus.circle.fill")
                            .resizable()
                            .symbolRenderingMode(.multicolor)
                            .frame(width: 17, height: 17)
                    }
                }
            }
            .padding(.vertical)
        }
        Spacer()
    }
}

