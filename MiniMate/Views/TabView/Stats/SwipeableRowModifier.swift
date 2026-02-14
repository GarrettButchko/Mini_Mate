import SwiftUI

struct ButtonSkim {
    var color: Color
    var systemImage: String
    var function: (() -> Void)? = nil
    var string: String? = nil
    var isShared: Bool {
        if function == nil && string != nil {
            return true
        } else {
            return false
        }
    }
}

struct SkimButtonView: View {
    let buttonSkim: ButtonSkim
    @Binding var offsetX: CGFloat
    
    var body: some View {
        Button {
            buttonSkim.function!()
        } label: {
            ZStack {
                RoundedRectangle(cornerRadius: 25)
                    .fill(Color(buttonSkim.color))
                if offsetX < -35 {
                    Image(systemName: buttonSkim.systemImage)
                        .font(.title2)
                        .foregroundStyle(.white)
                        .opacity(offsetX < -50 ? 1 : 0)
                        
                }
            }
            .clipped()
        }
    }
}

struct SkimShareLinkView: View {
    let buttonSkim: ButtonSkim
    @Binding var offsetX: CGFloat
    
    var body: some View {
        ShareLink(item: buttonSkim.string!) {
            ZStack {
                RoundedRectangle(cornerRadius: 25)
                    .fill(Color(buttonSkim.color))
                if offsetX < -35 {
                    Image(systemName: buttonSkim.systemImage)
                        .font(.title2)
                        .foregroundStyle(.white)
                        .opacity(offsetX < -50 ? 1 : 0)
                }
            }
            .clipped()
        }
    }
}

struct SwipeableRowModifier: ViewModifier {
    @Binding var editingID: String?
    @State private var offsetX: CGFloat = 0
    @State private var lastOffsetX: CGFloat = 0
    @State private var hasVibrated = false
    @State private var isPressed = false
    var id: String
    
    let pausePoint: CGFloat = -100
    let commitPoint: CGFloat = -50
    let resetPoint: CGFloat = 0
    let deletePoint: CGFloat = -220
    var showNonDeleteButtons: Bool { offsetX > deletePoint }
    
    let buttonOne: ButtonSkim?
    let buttonTwo: ButtonSkim?
    
    let deleteFunction: (() -> Void)?
    let buttonPressFunction: () -> Void
    
    func body(content: Content) -> some View {
        content
            .overlay(
                Color.main
                    .opacity(isPressed ? 0.32 : 0)
                    .mask(content)
                    .allowsHitTesting(false)
                    .animation(.easeInOut(duration: 0.12), value: isPressed)
            )
            .background(alignment: .trailing) {
                if editingID == id {
                    actionButtons
                        .opacity(offsetX < -10 ? 1 : 0)
                        .offset(x: -offsetX)   // keep buttons fixed as row moves
                        .frame(width: max(0, -offsetX - 10))
                        .transition(.opacity)
                        .padding(.leading)
                }
            }
            .offset(x: offsetX)
            .simultaneousGesture(dragGesture)
            .onTapGesture {
                if editingID != id {
                    isPressed = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
                        isPressed = false
                    }
                    buttonPressFunction()
                } else { /* If we are editing, let the taps pass through to buttons */ }
            }
            .onLongPressGesture(
                minimumDuration: 0.5,
                maximumDistance: 10,
                pressing: { pressing in
                    withAnimation(.easeInOut(duration: 0.12)) {
                        isPressed = pressing
                    }
                },
                perform: {
                    if editingID != id {
                        buttonPressFunction() // long‑press completed action
                    }
                }
            )
            .onChange(of: editingID) { oldValue, newValue in
                if newValue != id {
                    withAnimation(.easeOut(duration: 0.2)){
                        offsetX = resetPoint
                        lastOffsetX = resetPoint
                    }
                }
            }
    }
    
    var actionButtons: some View {
        VStack(spacing: 8){
            if let deleteFunc = deleteFunction{
                if showNonDeleteButtons {
                    Group{
                        if let buttonOne = buttonOne {
                            if buttonOne.isShared {
                                SkimShareLinkView(buttonSkim: buttonOne, offsetX: $offsetX)
                            } else {
                                SkimButtonView(buttonSkim: buttonOne, offsetX: $offsetX)
                            }
                        }
                        if let buttonTwo = buttonTwo {
                            if buttonTwo.isShared {
                                SkimShareLinkView(buttonSkim: buttonTwo, offsetX: $offsetX)
                            } else {
                                SkimButtonView(buttonSkim: buttonTwo, offsetX: $offsetX)
                            }
                        }
                    }
                    .transition(.opacity)
                }
                
                Button {
                    deleteFunc()
                } label: {
                    ZStack {
                        RoundedRectangle(cornerRadius: 25)
                            .fill(Color.red)
                        if offsetX < -35 {
                            Image(systemName: "xmark")
                                .foregroundStyle(.white)
                                .font(.title2)
                                .opacity(offsetX < commitPoint ? 1 : 0)
                        }
                    }
                }
            } else {
                if let buttonOne = buttonOne {
                    if buttonOne.isShared {
                        SkimShareLinkView(buttonSkim: buttonOne, offsetX: $offsetX)
                    } else {
                        SkimButtonView(buttonSkim: buttonOne, offsetX: $offsetX)
                    }
                }
                if let buttonTwo = buttonTwo {
                    if buttonTwo.isShared {
                        SkimShareLinkView(buttonSkim: buttonTwo, offsetX: $offsetX)
                    } else {
                        SkimButtonView(buttonSkim: buttonTwo, offsetX: $offsetX)
                    }
                }
            }
        }
    }
    
    var dragGesture: some Gesture {
        DragGesture(minimumDistance: 20)
            .onChanged { value in
                let totalOffset = lastOffsetX + value.translation.width
                let clamped = min(resetPoint, max(totalOffset, deletePoint - 80))
                if clamped != offsetX {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        offsetX = clamped
                    }
                }
                if offsetX < resetPoint, editingID != id {
                    editingID = id
                }
                if offsetX < deletePoint && !hasVibrated {
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    hasVibrated = true
                } else if offsetX > deletePoint {
                    hasVibrated = false
                }
            }
            .onEnded { value in
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    if offsetX < deletePoint {
                        deleteFunction?()
                        offsetX = resetPoint
                        editingID = nil
                    } else if offsetX < commitPoint {
                        offsetX = pausePoint
                    } else {
                        offsetX = resetPoint
                        editingID = nil
                    }
                    lastOffsetX = offsetX
                }
            }
    }
    
    var tapGesture: some Gesture {
        TapGesture()
            .onEnded { _ in
                if editingID != id {
                    buttonPressFunction()
                }
            }
    }
}

extension View {
    func swipeMod(editingID: Binding<String?>, id: String, buttonPressFunction: @escaping () -> Void, buttonOne: ButtonSkim? = nil, buttonTwo: ButtonSkim? = nil, deleteFunction: (() -> Void)? = nil) -> some View {
        self.modifier(SwipeableRowModifier(
            editingID: editingID,
            id: id,
            buttonOne: buttonOne,
            buttonTwo: buttonTwo,
            deleteFunction: deleteFunction,
            buttonPressFunction: buttonPressFunction
        ))
    }
}
