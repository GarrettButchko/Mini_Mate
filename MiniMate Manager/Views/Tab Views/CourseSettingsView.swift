//
//  CourseSettingsView.swift
//  MiniMate
//
//  Created by Garrett Butchko on 6/10/25.
//
import SwiftUI
import MarqueeText

struct CourseSettingsView: View {
    
    @EnvironmentObject var authModel: AuthViewModel
    @EnvironmentObject var viewModel: CourseViewModel
    
    @State var editCourse: Bool = false
    
    @State var showingPickerLogo: Bool = false
    @State var showingPickerAd: Bool = false
    @State var showReviewSheet: Bool = false
    
    @State var image: UIImage? = nil
    
    @State private var colorStringToDelete: String? = nil
    @State private var parIndexToDelete: Int? = nil
    @State private var showDeleteColor: Bool = false
    @State private var showColor: Bool = false
    
    @State private var scoreCardColorPicker: Bool = false
    
    let courseRepo = CourseRepository()
    
    @State var deleteTarget: ColorDeleteTarget? = nil
    
    enum ColorDeleteTarget: Identifiable {
        case courseColor(index: Int)

        var id: Int {
            switch self {
            case .courseColor(let i): return i
            }
        }
    }
    
    var body: some View {
        VStack{
            headerView
                .padding()
            ZStack{
                formView
                ColorPickerView(showColor: $showColor, scoreCardColorPicker: $scoreCardColorPicker) { color in
                    withAnimation() {
                    if scoreCardColorPicker {
                        viewModel.selectedCourse!.scoreCardColorDT = colorToString(color)
                    } else {
                        viewModel.selectedCourse!.courseColorsDT = (viewModel.selectedCourse!.courseColorsDT ?? []) + [colorToString(color)]
                    
                        viewModel.selectedCourse = viewModel.selectedCourse!
                    }
                    
                        courseRepo.addOrUpdateCourse(viewModel.selectedCourse!) { _ in }
                        showColor = false
                    }
                }
                .opacity(showColor ? 1 : 0)
                .animation(.spring(duration: 0.25, bounce: 0.4), value: showColor)
                .allowsHitTesting(showColor)
            }
        }
    }

    private var headerView: some View {
        VStack{
            
            HStack {
                Text("Settings")
                    .font(.title).fontWeight(.bold)
                Spacer()
                Button("User View"){
                    showReviewSheet = true
                }
                .sheet(isPresented: $showReviewSheet){
                    
                    var holeCount: Int { viewModel.selectedCourse!.pars?.count ?? 18 }
                    
                    let holes1 = (1...holeCount).map { number in
                        Hole(number: number, strokes: Int.random(in: 1...6))
                    }
                    let holes2 = (1...holeCount).map { number in
                        Hole(number: number, strokes: Int.random(in: 1...6))
                    }

                    
                    VStack{
                        Capsule()
                            .frame(width: 38, height: 6)
                            .foregroundColor(.gray)
                            .padding(.top)
                        GameReviewView(viewManager: ViewManager(), game:
                                        Game(
                                            id: "EXAMPLE",
                                            date: Date(),
                                            completed: true,
                                            numberOfHoles: 18,
                                            started: true,
                                            dismissed: true,
                                            live: false,
                                            lastUpdated: Date(),
                                            courseID: viewModel.selectedCourse!.id,
                                            players: [
                                                Player(id: "1", userId: "Example 1", name: "Garrett", inGame: false, holes: holes1),
                                                Player(id: "2", userId: "Example 2", name: "Joey", inGame: false, holes: holes2)
                                            ]
                                        ), showBackToStatsButton: true, isInCourseSettings: true
                        )
                    }
                }
            }
        }
    }
    
    @State private var newPassword = ""
    @State private var confirmPassword = ""
    @State private var showNewPassword = false
    @State private var showPassword: Bool = false
    @State private var showChangePasswordMenu: Bool = false
    
    private var isValidPassword: Bool {
        !newPassword.isEmpty && newPassword == confirmPassword
    }
    
    private var formView: some View {
        
        Form{
            if let courseTier = viewModel.selectedCourse?.tier, courseTier >= 1{
                Section("Course") {
                    
                    // -----
                    
                    HStack {
                        Text("Id:")
                        Spacer()
                        Text(viewModel.selectedCourse!.id)
                    }
                    
                    // -----
                    
                    HStack {
                        Text("Name:")
                        Spacer()
                        Text(viewModel.selectedCourse!.name)
                    }
                    
                    // -----
                    
                    HStack {
                        Text("Tier:")
                        Spacer()
                        Text(String(courseTier))
                    }
                    
                    // ------
                    
                    HStack{
                        Text("Password:")
                        
                        if showPassword {
                            Text(viewModel.selectedCourse!.password)
                        } else {
                            Text("••••••••••")
                        }
                        Spacer()
                        Button {
                            showPassword.toggle()
                        } label: {
                            !showPassword ? Image(systemName: "eye").foregroundColor(.blue) : Image(systemName: "eye.slash").foregroundColor(.blue)
                        }
                        
                    }
                    
                    Button {
                        withAnimation(){
                            showChangePasswordMenu.toggle()
                        }
                    } label: {
                        showChangePasswordMenu ? Text("Hide") : Text("Change Password")
                            .foregroundColor(.blue)
                    }
                    
                    
                    if showChangePasswordMenu {
    
                        VStack{
                            TextField("New Password", text: $newPassword)
                                .padding(12)
                                .background(
                                    RoundedRectangle(cornerRadius: 15, style: .continuous)
                                        .fill(Color(.systemBackground))
                                        .shadow(color: .black.opacity(0.12), radius: 3, y: 1)
                                )
                        
                            // Confirm Password
                            TextField("Confirm Password", text: $confirmPassword)
                                .padding(12)
                                .background(
                                    RoundedRectangle(cornerRadius: 15, style: .continuous)
                                        .fill(Color(.systemBackground))
                                        .shadow(color: .black.opacity(0.12), radius: 3, y: 1)
                                )
                            
                            // Save button
                            Button(action: {
                                guard !newPassword.isEmpty, newPassword == confirmPassword else { return }
                                
                                viewModel.selectedCourse!.password = newPassword
                                
                                courseRepo.addOrUpdateCourse(viewModel.selectedCourse!) { complete in
                                    if complete {
                                        if let userID = authModel.userModel?.id {
                                            courseRepo.keepOnlyAdminID(id: userID, courseID: viewModel.selectedCourse!.id) { _ in }
                                        }
                                    }
                                }
                                
                                newPassword = ""
                                confirmPassword = ""
                                showNewPassword = false
                                showChangePasswordMenu = false
                            }) {
                                ZStack{
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(
                                            isValidPassword
                                            ? Color.blue
                                            : Color.gray
                                        )
                                    HStack{
                                        Text(" ")
                                        Spacer()
                                        Text("Save")
                                        Spacer()
                                        Text(" ")
                                    }
                                    .padding()
                                    .foregroundColor(.white)
                                }
                                .frame(maxWidth: .infinity)
                            }
                            .disabled(!isValidPassword)
                        }
                    }

                    // ------
                    
                    HStack {
                        Text("Logo:")
                        Spacer()
                        Button {
                            withAnimation{
                                showingPickerLogo = true
                            }
                        } label: {
                            if let courseLogo = viewModel.selectedCourse?.logo{
                                AsyncImage(url: URL(string: courseLogo)) { phase in
                                    switch phase {
                                    case .empty:
                                        ProgressView()
                                            .frame(width: 60)
                                    case .success(let image):
                                        image
                                            .resizable()
                                            .scaledToFill()
                                            .frame(width: 60)
                                            .clipped()
                                    case .failure:
                                        Image(systemName: "photo")
                                            .resizable()
                                            .scaledToFit()
                                            .frame(width: 60)
                                            .foregroundColor(.gray)
                                            .background(Color.gray.opacity(0.2))
                                    @unknown default:
                                        EmptyView()
                                    }
                                }
                            } else {
                                Image(systemName: "photo")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 60)
                                    .foregroundColor(.gray)
                                    .background(Color.gray.opacity(0.2))
                            }
                        }
                        .sheet(isPresented: $showingPickerLogo) {
                            PhotoPicker(image: $image)
                                .onChange(of: image) { old ,newImage in
                                    guard let img = newImage else { return }
                                    
                                    courseRepo.uploadCourseImages(id: viewModel.selectedCourse!.id, img, key: "logoImage") { result in
                                        switch result {
                                        case .success(let url):
                                            viewModel.selectedCourse!.logo = url.absoluteString
                                            courseRepo.addOrUpdateCourse(viewModel.selectedCourse!) { _ in }
                                        case .failure(let error):
                                            print("❌ Photo upload failed:", error)
                                        }
                                    }
                                }
                        }
                    }
                    
                    
                    HStack{
                        Text("Scorecard Color:")
                        Spacer()
                        ColorHolderView(color: viewModel.selectedCourse?.scoreCardColor, showDeleteColor: $showDeleteColor, showColor: $showColor, showDeleteAlert: true,
                                        showFunction:{
                            scoreCardColorPicker = true
                        }, deleteFunction: {
                            guard var course = viewModel.selectedCourse else { return }
                                
                            if scoreCardColorPicker {
                                print("DELETE scorecard")
                                // Clear local state
                                withAnimation(){
                                    course.scoreCardColorDT = nil
                                    viewModel.selectedCourse = course
                                }
                                
                                // Clear remote state (explicit delete)
                                courseRepo.deleteCourseItem(
                                    courseID: course.id,
                                    dataName: "scoreCardColorDT"
                                )
                            }
                        })
                    }
                    
                    VStack{
                        HStack{
                            Text("Course Colors")
                        }
                        ScrollView(.horizontal) {
                            HStack{
                                if let colors = viewModel.selectedCourse?.courseColorsDT {
                                    ForEach(Array(colors.enumerated()), id: \.offset) { index, dt in
                                        let color = stringToColor(dt)

                                        ColorHolderView(
                                            color: color,
                                            showDeleteColor: $showDeleteColor,
                                            showColor: $showColor,
                                            showDeleteAlert: false
                                        ) {
                                            scoreCardColorPicker = false
                                        } deleteFunction: {
                                            deleteTarget = .courseColor(index: index)
                                        }
                                    }
                                }

                                ColorHolderView(showDeleteColor: $showDeleteColor, showColor: $showColor, showDeleteAlert: false) {
                                    scoreCardColorPicker = false
                                } deleteFunction: { }
                            }
                        }
                        .alert(item: $deleteTarget) { target in
                            Alert(
                                title: Text("Delete Color"),
                                message: Text("Are you sure?"),
                                primaryButton: .destructive(Text("Delete")) {
                                    guard var course = viewModel.selectedCourse else { return }

                                    switch target {
                                    case .courseColor(let index):
                                        var colors = course.courseColorsDT ?? []
                                        guard colors.indices.contains(index) else { return }

                                        colors.remove(at: index)

                                        withAnimation {
                                            course.courseColorsDT = colors
                                            viewModel.selectedCourse = course
                                        }

                                        if colors.isEmpty {
                                            courseRepo.deleteCourseItem(
                                                courseID: course.id,
                                                dataName: "courseColorsDT"
                                            )
                                        } else {
                                            courseRepo.setCourseItem(
                                                courseID: course.id,
                                                dataName: "courseColorsDT",
                                                object: colors
                                            )
                                        }
                                    }
                                },
                                secondaryButton: .cancel()
                            )
                        }
                    }
                    
                    
                    HStack {
                        Text("Link:")
                        Spacer()
                        TextField("Link", text: Binding(
                            get: { viewModel.selectedCourse!.link ?? "" },
                            set: {
                                viewModel.selectedCourse!.link = $0.isEmpty ? nil : $0
                                if viewModel.selectedCourse!.link == nil {
                                    courseRepo.deleteCourseItem(courseID: viewModel.selectedCourse!.id, dataName: "link")
                                } else {
                                    courseRepo.addOrUpdateCourse(viewModel.selectedCourse!) { _ in }
                                }
                            }
                        ))
                        .padding(12)
                        .background(
                            RoundedRectangle(cornerRadius: 15, style: .continuous)
                                .fill(Color(.systemBackground))
                                .shadow(color: .black.opacity(0.12), radius: 3, y: 1)
                        )
                    }
                }
            }
            
            if let courseTier = viewModel.selectedCourse?.tier, courseTier >= 2 {
                Section("Ad") {
                    
                        
                        Toggle("Ad Active:", isOn: Binding(
                            get: { viewModel.selectedCourse!.customAdActive },
                            set: { newValue in
                                viewModel.selectedCourse!.customAdActive = newValue
                                courseRepo.addOrUpdateCourse(viewModel.selectedCourse!) { _ in }
                            }
                        ))
                        .toggleStyle(SwitchToggleStyle())
                    
                    
                    if viewModel.selectedCourse!.customAdActive {
                        VStack {
                            HStack{
                                Text("Ad Title:")
                                Spacer()
                            }
                            
                            Spacer()
                            TextEditor(text: Binding(
                                get: { viewModel.selectedCourse!.adTitle ?? "" },
                                set: {
                                    // Limit to 10 characters manually
                                    let newValue = String($0.prefix(40))
                                    viewModel.selectedCourse!.adTitle = newValue.isEmpty ? nil : newValue
                                    if viewModel.selectedCourse!.adTitle == nil {
                                        courseRepo.deleteCourseItem(courseID: viewModel.selectedCourse!.id, dataName: "adTitle")
                                    } else {
                                        courseRepo.addOrUpdateCourse(viewModel.selectedCourse!) { _ in }
                                    }
                                }
                            ))
                            .frame(minHeight: 40, maxHeight: 80)
                            .padding(12)
                            .background(
                                RoundedRectangle(cornerRadius: 15, style: .continuous)
                                    .fill(Color(.systemBackground))
                                    .shadow(color: .black.opacity(0.12), radius: 3, y: 1)
                            )
                        }
                        VStack {
                            HStack{
                                Text("Ad Description:")
                                Spacer()
                            }
                            Spacer()
                            TextEditor(text: Binding(
                                get: { viewModel.selectedCourse!.adDescription ?? "" },
                                set: {
                                    let newValue = String($0.prefix(80))
                                    viewModel.selectedCourse!.adDescription = newValue.isEmpty ? nil : newValue
                                    if viewModel.selectedCourse!.adDescription == nil {
                                        courseRepo.deleteCourseItem(courseID: viewModel.selectedCourse!.id, dataName: "adDescription")
                                    } else {
                                        courseRepo.addOrUpdateCourse(viewModel.selectedCourse!) { _ in }
                                    }
                                }
                            ))
                            .frame(minHeight: 60, maxHeight: 120)
                            .padding(12)
                            .background(
                                RoundedRectangle(cornerRadius: 15, style: .continuous)
                                    .fill(Color(.systemBackground))
                                    .shadow(color: .black.opacity(0.12), radius: 3, y: 1)
                            )
                        }
                        
                        HStack {
                            Text("Ad Link:")
                            Spacer()
                            TextField("Ad Link", text: Binding(
                                get: { viewModel.selectedCourse!.adLink ?? "" },
                                set: {
                                    viewModel.selectedCourse!.adLink = $0.isEmpty ? nil : $0
                                    if viewModel.selectedCourse!.adLink == nil {
                                        courseRepo.deleteCourseItem(courseID: viewModel.selectedCourse!.id, dataName: "adLink")
                                    } else {
                                        courseRepo.addOrUpdateCourse(viewModel.selectedCourse!) { _ in }
                                    }
                                }
                            ))
                            .padding(12)
                            .background(
                                RoundedRectangle(cornerRadius: 15, style: .continuous)
                                    .fill(Color(.systemBackground))
                                    .shadow(color: .black.opacity(0.12), radius: 3, y: 1)
                            )
                        }
                        HStack {
                            Text("Ad Image:")
                            Spacer()
                            Button {
                                withAnimation{
                                    showingPickerAd = true
                                }
                            } label: {
                                if let courseImage = viewModel.selectedCourse?.adImage{
                                    AsyncImage(url: URL(string: courseImage)) { phase in
                                        switch phase {
                                        case .empty:
                                            ProgressView()
                                                .frame(width: 60)
                                        case .success(let image):
                                            image
                                                .resizable()
                                                .scaledToFill()
                                                .frame(width: 60)
                                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                                .clipped()
                                        case .failure:
                                            Image(systemName: "photo")
                                                .resizable()
                                                .scaledToFit()
                                                .frame(width: 60)
                                                .foregroundColor(.gray)
                                                .background(Color.gray.opacity(0.2))
                                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                        @unknown default:
                                            EmptyView()
                                        }
                                    }
                                } else {
                                    Image(systemName: "photo")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 60)
                                        .foregroundColor(.gray)
                                        .background(Color.gray.opacity(0.2))
                                        .clipShape(RoundedRectangle(cornerRadius: 12))
                                }
                            }
                            .sheet(isPresented: $showingPickerAd) {
                                PhotoPicker(image: $image)
                                    .onChange(of: image) { old ,newImage in
                                        guard let img = newImage else { return }
                                        
                                        courseRepo.uploadCourseImages(id: viewModel.selectedCourse!.id, img, key: "adImage") { result in
                                            switch result {
                                            case .success(let url):
                                                viewModel.selectedCourse!.adImage = url.absoluteString
                                                courseRepo.addOrUpdateCourse(viewModel.selectedCourse!) { _ in }
                                            case .failure(let error):
                                                print("❌ Photo upload failed:", error)
                                            }
                                        }
                                    }
                            }
                        }
                    }
                }
            }
            
            
            Section ("Pars"){
                
                if let pars = viewModel.selectedCourse?.pars {
                    ForEach(pars.indices, id: \.self) { index in
                        HStack {
                            Text("Hole \(index + 1):")
                            Spacer()

                            NumberPickerView(
                                selectedNumber: Binding(
                                    get: { viewModel.selectedCourse!.pars?[index] ?? 0 },
                                    set: {
                                        viewModel.selectedCourse!.pars?[index] = $0
                                        courseRepo.addOrUpdateCourse(viewModel.selectedCourse!) { _ in }
                                    }
                                ),
                                minNumber: 0,
                                maxNumber: 10
                            )
                            .frame(width: 75)
                        }
                    }
                    .onDelete { indices in
                        indices.forEach { index in
                            withAnimation {
                                viewModel.selectedCourse!.pars?.remove(at: index)
                                courseRepo.addOrUpdateCourse(viewModel.selectedCourse!) { _ in }
                            }
                        }
                    }
                }
                
                Button {
                    withAnimation(){
                        viewModel.selectedCourse!.pars?.append(0)
                        courseRepo.addOrUpdateCourse(viewModel.selectedCourse!) { _ in }
                    }
                } label: {
                    HStack{
                        Image(systemName: "plus")
                        Text("Add Par")
                    }
                }
            }
        }
    }
    
    func colorToString(_ color: Color) -> String {
        return String(describing: color)
    }
    func stringToColor(_ string: String) -> Color {
        switch string.lowercased() {
        case "red": return .red
        case "orange": return .orange
        case "yellow": return .yellow
        case "green": return .green
        case "cyan": return .cyan
        case "blue": return .blue
        case "indigo": return .indigo
        case "purple": return .purple
        case "pink": return .pink
        case "brown": return .brown
        default:
            return .clear // fallback (important)
        }
    }

}
