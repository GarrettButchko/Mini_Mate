//
//  StatCard.swift
//  MiniMate
//
//  Created by Garrett Butchko on 5/13/25.
//
import SwiftUI

struct StatCard: View {
    @Environment(\.colorScheme) private var colorScheme
    @State var showInfo: Bool = false
    var title: String
    var value: String
    var color: Color? = nil
    var cornerRadius: CGFloat = 12
    var cardHeight: CGFloat? = nil
    var infoText: String = "No Text Yet"
    
    var body: some View {
        
            VStack(spacing: 8) {
                HStack{
                    Text(title)
                        .foregroundStyle(.mainOpp)
                        .font(.system(size: 14, weight: .semibold))
                    
                    Spacer()
                    
                    Button {
                        showInfo = true
                    } label: {
                        Image(systemName: "info.circle")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 20, height: 20)
                            .foregroundStyle(.blue)
                        
                    }
                    .alert("Info", isPresented: $showInfo) {
                        Button("OK") {}
                    } message: {
                        Text(infoText)
                    }
                }
                
                HStack{
                    Text(value)
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundStyle(
                            color != nil
                            ? AnyShapeStyle(color!)
                            : AnyShapeStyle(
                                LinearGradient(
                                    colors: [.blue, .green],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                        )
                    Spacer()
                }
            }
        .padding()
        .frame(height: cardHeight)
        .background(.subTwo)
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
    }
}
