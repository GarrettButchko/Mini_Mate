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
            HStack(alignment: .center){
                Button {
                    viewManager.navigateToCourseList()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        viewModel.setCourse(course: nil)
                    }
                } label: {
                    Image(systemName: "chevron.left")
                        .resizable()
                        .scaledToFit()
                        .foregroundStyle(.blue)
                        .frame(width: 20, height: 20)
                }
                .padding(.horizontal, 8)
                    
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
            
            TitleView(colors: viewModel.selectedCourse?.courseColors, isManager: true)
                .frame(height: 150)
                .padding(.bottom)
            
            ZStack(alignment: .top){
                
                ScrollView{
                    VStack (spacing: 16){
                        Rectangle()
                            .fill(Color.clear)
                            .frame(height: 94)
                        
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
                    }
                }
                
                VStack{
                    HStack(spacing: 14){
                        mainViewButton(title: "Leaderboard", icon: "flag.pattern.checkered", color: Color.green) {
                            // MARK: TODO
                        }
                        
                        mainViewButton(title: "Tournament", icon: "medal", color: Color.orange) {
                            // MARK: TODO
                        }
                    }
                }
                .padding()
                .background(content: {
                    RoundedRectangle(cornerRadius: 25)
                        .ifAvailableGlassEffect()
                })
            }
            Spacer()
        }
        .padding()
    }
    
    func mainViewButton(title: String, icon: String? = nil, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                if let icon = icon {
                    Image(systemName: icon)
                }
                Text(title)
                    .fontWeight(.semibold)
            }
            .padding(10)
            .frame(maxWidth: .infinity, minHeight: 60)
            .background {
                RoundedRectangle(cornerRadius: 17)
                    .foregroundStyle(color)
            }
            .foregroundColor(.white)
        }
    }
}
