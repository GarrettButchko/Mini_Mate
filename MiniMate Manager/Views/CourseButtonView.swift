//
//  CourseButtonView.swift
//  MiniMate Manager
//
//  Created by Garrett Butchko on 12/19/25.
//

import SwiftUI

struct CourseButtonView: View {
    
    let course: Course
    
    var body: some View {
        HStack {
            VStack(alignment: .leading,spacing: 6){
                Text(course.name)
                    .font(.headline)
                    .foregroundStyle(.primary)
                Text(course.id)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            if let logo = course.logo,
               let url = URL(string: logo) {

                AsyncImage(url: url) { phase in
                    switch phase {
                    case .empty:
                        ProgressView()
                            .frame(height: 50)

                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFit()
                            .frame(height: 50)

                    case .failure:
                        Image(systemName: "photo")
                            .resizable()
                            .scaledToFit()
                            .frame(height: 50)
                            .foregroundStyle(.secondary)

                    @unknown default:
                        EmptyView()
                    }
                }
            } else {
                Image(systemName: "chevron.right")
                    .resizable()
                    .scaledToFit()
                    .frame(height: 20)
                    .foregroundStyle(.mainOpp)
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 25)
                .fill(.ultraThinMaterial)
        )
    }
}
