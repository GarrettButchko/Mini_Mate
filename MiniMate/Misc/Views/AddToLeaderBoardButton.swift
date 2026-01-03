//
//  AddToLeaderBoardButton.swift
//  MiniMate
//
//  Created by Garrett Butchko on 6/12/25.
//
import SwiftUI

struct AddToLeaderBoardButton: View{
    
    @State var course: Course?
    @State var alert: Bool = false
    @State var added: Bool = false
    @State var email: String = ""
    
    let player: Player
    
    let courseLeaderBoardRepo = CourseLeaderboardRepository()
    
    var body: some View {
        if let course = course, let courseTier = course.tier, !(ProfanityFilter.containsBlockedWord(player.name) && player.incomplete) && !added && courseTier >= 2 && player.email != nil{
            Button{
                courseLeaderBoardRepo.sumbitScore(courseID: course.id, player: player) { _ in }
            } label: {
                ZStack{
                    RoundedRectangle(cornerRadius: 25)
                        .foregroundStyle(.blue)
                    HStack{
                        Image(systemName: "plus")
                            .font(.caption)
                            .foregroundStyle(.white)
                        Text("Leaderboard")
                            .font(.caption)
                            .foregroundStyle(.white)
                    }
                }
                .frame(width: 120, height: 20)
            }
            .transition(.opacity.combined(with: .move(edge: .top)))
        }
    }
}

