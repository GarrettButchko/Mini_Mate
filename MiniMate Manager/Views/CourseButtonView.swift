//
//  CourseButtonView.swift
//  MiniMate Manager
//
//  Created by Garrett Butchko on 12/19/25.
//

import SwiftUI

struct CourseButtonView: View {
    
    @EnvironmentObject var viewManager: ViewManager
    @ObservedObject var viewModel: CourseViewModel
    let course: Course
    
    var body: some View {
        Button {
            viewModel.setCourse(course: course)
            viewManager.navigateToCourseTab(1, viewModel: viewModel)
        } label: {
            HStack {
                VStack(alignment: .leading,spacing: 6){
                    Text(course.name)
                        .font(.headline)
                        .foregroundStyle(.mainOpp)
                    Text(course.id)
                        .font(.subheadline)
                        .foregroundStyle(.subOpp)
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
}
