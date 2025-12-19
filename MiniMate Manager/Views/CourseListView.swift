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
    
    private var userRepo: UserRepository { UserRepository(context: context)}
    
    @State private var isSheetPresented: Bool = false
    
    var body: some View {
        VStack{
            HStack{
                Text("Game Stats")
                    .font(.title).fontWeight(.bold)
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
        }
        .padding()
        .onAppear {
            userRepo.loadOrCreateUser(id: authModel.currentUserIdentifier!, authModel: authModel) {}
        }
        
        Text("Course List")
    }
}
