//
//  MainView.swift
//  MiniMate Manager
//
//  Created by Garrett Butchko on 12/18/25.
//

import SwiftUI
import FirebaseAuth

struct MainView: View {
    @Environment(\.modelContext) private var context
    
    @EnvironmentObject var authModel: AuthViewModel
    @EnvironmentObject var viewModel: CourseViewModel
    @EnvironmentObject var viewManager: ViewManager
    
    
    @State var showLeaderBoardSheet: Bool = false
    @State var showTournamentSheet: Bool = false
    @State var isSheetPresented: Bool = false
    
    var body: some View {
        VStack{
            HStack {
                Button {
                    viewManager.navigateToCourseList()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        viewModel.setCourse(course: nil)
                    }
                } label: {
                    Image(systemName: "chevron.left")
                }
                    
                VStack(alignment: .leading, spacing: 2) {
                    Text("Course Dashboard For,")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    Text(viewModel.selectedCourse?.name ?? "No Course Selected")
                        .font(.title2)
                        .fontWeight(.semibold)
                }
                
                Spacer()
                
                Button(action: {
                    isSheetPresented = true
                }) {
                    if let photoURL = authModel.firebaseUser?.photoURL {
                        AsyncImage(url: photoURL) { image in
                            image
                                .resizable()
                                .scaledToFill()
                        } placeholder: {
                            Image("logoOpp")
                                .resizable()
                                .scaledToFill()
                        }
                        .frame(width: 40, height: 40)
                        .clipShape(Circle())
                    } else {
                        Image("logoOpp")
                            .resizable()
                            .scaledToFill()
                            .frame(width: 40, height: 40)
                    }
                }
                .sheet(isPresented: $isSheetPresented) {
                    ProfileView(
                        viewManager: viewManager,
                        authModel: authModel,
                        isSheetPresent: $isSheetPresented, context: context
                    )
                }
            }
            .padding([.top, .horizontal])
            
            TitleView()
                .frame(height: 150)
                .padding(.bottom)
            
            ZStack(alignment: .top){
                
                ScrollView{
                    Rectangle()
                        .fill(Color.clear)
                        .frame(height: 120)
                    
                    HStack{
                        Spacer()
                        Text("ADD STUFF HERE")
                        Spacer()
                    }
                    .padding()
                    .background {
                        RoundedRectangle(cornerRadius: 25)
                            .fill(.ultraThinMaterial)
                    }
                    .padding()
                }
                
                VStack{
                    HStack(spacing: 8){
                        Button {
                            showLeaderBoardSheet = true
                        } label: {
                            HStack{
                                Image(systemName: "flag.pattern.checkered")
                                Text("Leaderboard")
                            }
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 40)
                            .padding(.horizontal)
                            .background {
                                RoundedRectangle(cornerRadius: 17)
                                    .foregroundStyle(Color.orange)
                            }
                        }
                        Button {
                            showLeaderBoardSheet = true
                        } label: {
                            HStack{
                                Image(systemName: "medal")
                                Text("Tournament")
                            }
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 40)
                            .padding(.horizontal)
                            .background {
                                RoundedRectangle(cornerRadius: 17)
                                    .foregroundStyle(Color.green)
                            }
                        }
                    }
                }
                .padding()
                .background(content: {
                    RoundedRectangle(cornerRadius: 25)
                        .ifAvailableGlassEffect()
                })
                .padding(.horizontal)
            }
            Spacer()
        }
    }
}
