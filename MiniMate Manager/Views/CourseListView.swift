//
//  CourseListView.swift
//  MiniMate Manager
//
//  Created by Garrett Butchko on 12/18/25.
//

import SwiftUI
import FirebaseAuth

struct CourseListView: View {
    @Environment(\.modelContext) private var context
    @EnvironmentObject var authModel: AuthViewModel
    @EnvironmentObject var viewManager: ViewManager
    @EnvironmentObject var viewModel: CourseViewModel
    
    private var userRepo: UserRepository { UserRepository(context: context)}
    
    @State private var isSheetPresented: Bool = false
    @State private var showUnsuccessfulAlert: Bool = false
    @State private var isRotating: Bool = false
    
    var body: some View {
        VStack{
            HStack{
                Text("Courses")
                    .font(.title).fontWeight(.bold)
                Spacer()
                
                Button(action: {
                    withAnimation(){
                        isRotating = true
                        viewModel.getCourses()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                            isRotating = false
                        }
                    }
                }) {
                    Image(systemName: "arrow.trianglehead.2.clockwise")
                        .rotationEffect(.degrees(isRotating ? 360 : 0))
                        .font(.title2)
                        .foregroundColor(.blue)
                        .frame(width: 30, height: 30)
                }
                
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
            
            if viewModel.loadingCourse {
                VStack{
                    Spacer()
                    ProgressView()
                    Spacer()
                }
            } else {
                ScrollView{
                    VStack(spacing: 12){
                        Rectangle()
                            .frame(height: 10)
                            .foregroundStyle(.clear)
                        
                        if let message = viewModel.message {
                            VStack(spacing: 6) {
                                Text(message)
                                    .font(.headline)
                                    .foregroundStyle(.primary)
                                
                                if viewModel.timeRemaining > 0 {
                                    Text("Try again in \(max(0, Int(ceil(viewModel.timeRemaining)))) seconds")
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 25)
                                    .fill(.ultraThinMaterial)
                            )
                        }
                        
                        ForEach(viewModel.userCourses) { course in
                            CourseButtonView(viewModel: viewModel, course: course)
                        }
                        
                        Button {
                            viewModel.showAddCourseAlert = true
                        } label: {
                            ZStack{
                                RoundedRectangle(cornerRadius: 25)
                                    .foregroundStyle(.blue)
                                    .frame(height: 60)
                                HStack(alignment: .center){
                                    Image(systemName: "plus")
                                        .foregroundStyle(.white)
                                    Text(viewModel.hasCourse ? "Add a new course" : "Add your first course")
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                        .foregroundStyle(.white)
                                }
                            }
                            .opacity(viewModel.timeRemaining > 0 ? 0.5 : 1)
                        }
                        .disabled(viewModel.timeRemaining > 0)
                        Spacer()
                    }
                }
            }
        }
        .padding()
        .onReceive(viewModel.timer) { _ in
            viewModel.tick()
        }
        .alert("Add Course", isPresented: $viewModel.showAddCourseAlert) {
            TextField("Password", text: $viewModel.password)

            Button("Add", role: .none) {
                viewModel.tryPassword { _ in
                    viewModel.password = ""
                    viewModel.showAddCourseAlert = false
                }
            }
            .disabled(viewModel.password.isEmpty)

            Button("Cancel", role: .cancel) {
                viewModel.password = ""
                viewModel.showAddCourseAlert = false
            }
        } message: {
            Text("Enter course password to begin.")
        }
        .onAppear {
            viewModel.bind(authModel: authModel)
            userRepo.loadOrCreateUser(id: authModel.currentUserIdentifier!, authModel: authModel) { _ in
                if viewModel.userCourses.isEmpty {
                    if authModel.userModel?.adminCourses.count ?? 0 > 1 {
                        viewModel.getCourses()
                    } else if authModel.userModel?.adminCourses.count == 1{
                        viewModel.getCourse {
                            viewManager.navigateToCourseTab(1)
                        }
                    } else {
                        viewModel.loadingCourse = false
                    }
                }
            }
        }
    }
}
