import SwiftUI

struct TitleView: View {
    
    var colors: [Color]
    
    init(colors: [Color]?) {
        self.colors = colors ?? [.red, .orange, .yellow, .green, .blue, .purple, .indigo, .pink]
    }
    
    var body: some View {
        ZStack {
            // Foreground Title text
            VStack {
                HStack {
                    Text("Mini")
                        .font(.largeTitle)
                        .foregroundColor(.mainOpp)
                        .bold()
                    Spacer()
                }
                HStack {
                    Spacer()
                    Text("Mate")
                        .font(.largeTitle)
                        .foregroundColor(.mainOpp)
                        .bold()
                }
            }
            .frame(width: 130)
            
            // Orbiting background
            OrbitingCirclesView(colors: colors)
                .frame(width: 220, height: 220)
                .clipped()
        }
        .frame(width: 220, height: 220)
    }
}

// MARK: - Orbiting Circle Model
struct OrbitingCircle {
    let angleOffset: Double
    let size: Double
    let speedMultiplier: Double
    let verticalScale: Double
    let color: Color
}

// MARK: - Circle Animation View
struct OrbitingCirclesView: View {
    var orbitingCircles: [OrbitingCircle]
    // Custom initializer
    init(colors: [Color]) {
        // Initialize orbitingCircles after `colors` is available
        self.orbitingCircles = (0..<8).map { index in
            OrbitingCircle(
                angleOffset: Double(index) * (360 / 8),
                size: Double.random(in: 10...20),
                speedMultiplier: Double.random(in: 0.8...1.2),
                verticalScale: Double.random(in: 30...60),
                color: colors[index % colors.count]
            )
        }
    }
    
    
    var body: some View {
        TimelineView(.animation) { timeline in
            let date = timeline.date.timeIntervalSinceReferenceDate
            let baseRotation = date * 50
            
            ZStack {
                ForEach(orbitingCircles, id: \.angleOffset) { circle in
                    let angle = baseRotation * circle.speedMultiplier + circle.angleOffset
                    let radians = angle * .pi / 180
                    
                    let x = 100 * cos(radians)
                    let y = circle.verticalScale * sin(radians) // <- height variation
                    let scale = 0.5 + 0.5 * (1 + sin(radians))
                    
                    Circle()
                        .fill(circle.color)
                        .frame(width: circle.size * scale, height: circle.size * scale)
                        .offset(x: x, y: y)
                        .opacity(0.4 + 0.6 * scale)
                }
            }
        }
    }
}
