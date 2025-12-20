//
//  CourseListViewModel.swift
//  MiniMate
//
//  Created by Garrett Butchko on 12/19/25.
//

import Foundation
import Combine
import SwiftUI

@MainActor
final class CourseListViewModel: ObservableObject {

    @Published var password: String = ""
    @Published var message: String? = nil
    @Published var showAddCourseAlert: Bool = false
    
    private var authModel: AuthViewModel?
    @Published var userCourses: [Course] = []
    private let courseRepo = CourseRepository()
    private let userRepo = UserRepository()
    
    @Published var timeRemaining: TimeInterval = 0
    @Published var failedAttempts: Int = 0
    let failedLimit: Int = 5
    private let ttl: TimeInterval = 30
    private var lastUpdated = Date()
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    var hasCourse: Bool {
        if let adminCourses = authModel?.userModel?.adminCourses, !adminCourses.isEmpty {
            return true
        } else {
            return false
        }
    }
    
    var blockAddingCourse: Bool {
        return (failedAttempts >= failedLimit)
    }
    
    func tick() {
        guard timeRemaining > 0 else { return }

        let expire = lastUpdated.addingTimeInterval(ttl)
        timeRemaining = max(0, expire.timeIntervalSinceNow)

        if timeRemaining == 0 {
            withAnimation(){
                message = nil
                failedAttempts = 0
            }
        }
    }

    func startTimer() {
        guard timeRemaining == 0 else { return } // ⬅️ critical
        lastUpdated = Date()
        timeRemaining = ttl
    }

    
    func bind(authModel: AuthViewModel) {
        self.authModel = authModel
    }
    
    
    
    func getCourses(){
        if hasCourse{
            courseRepo.fetchCourses(ids: (authModel?.userModel?.adminCourses)!) { courses in
                withAnimation(){
                    self.userCourses = courses
                }
            }
        }
    }
    
    func tryPassword(completion: @escaping (Bool) -> Void) {
        courseRepo.findCourseIDWithPassword(withPassword: password) { courseID in
            Task { @MainActor in
                if let courseID, let authModel = self.authModel {
                    // Update model on main thread
                    
                    if authModel.userModel?.adminCourses.contains(courseID) == true {
                        withAnimation(){
                            self.message = "Course Already Added"
                        }
                        completion(false)
                    } else {
                        self.authModel?.userModel?.adminCourses.append(courseID)
                        self.userRepo.saveRemote(id: authModel.currentUserIdentifier!, userModel: authModel.userModel!) { _ in }
                        self.getCourses()
                        self.message = nil
                        completion(true)
                    }
                    
                } else {
                    self.failedAttempts += 1
                    
                    if self.failedAttempts < self.failedLimit {
                        withAnimation(){
                            self.message = "Unsuccessful attempt. Please try again."
                        }
                    } else {
                        withAnimation(){
                            self.message = "Too many attempts"
                            self.startTimer()
                        }
                    }
                    completion(false)
                }
            }
        }
    }
}
