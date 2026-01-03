//
//  DonationOption.swift
//  MiniMate
//
//  Created by Garrett Butchko on 4/30/25.
//

import SwiftUI
import StoreKit

struct ProView: View {
    @State private var thankYou = false
    @State private var errorMessage: String?
    @Binding var showSheet: Bool
    @ObservedObject var authModel: AuthViewModel
    @StateObject var iapManager = IAPManager()
    
    let benefits = [
        "Ad-free experience",
        "Store unlimited played games",
        "Early access to new content",
        "More Coming soon..."
    ]
    
    var body: some View {
        
        Capsule()
            .frame(width: 38, height: 6)
            .foregroundColor(.gray)
            .padding(10)
        
        VStack(spacing: 24) {
            
            Spacer()
            
            Text("Buy Pro Now!")
                .font(.largeTitle.bold())
                .padding(.top)
            
            Text("Your support helps to build awesome new features. Thank you! 🙏")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Spacer()
            
            VStack(alignment: .leading) {
                ForEach(benefits, id: \.self) { benefit in
                    HStack() {
                        Image(systemName: "checkmark.seal.fill")
                            .foregroundColor(.yellow)
                        Text(benefit)
                            .font(.headline)
                        Spacer()
                    }
                }
                .padding()
            }
            .background(){
                RoundedRectangle(cornerRadius: 25)
                    
                    .fill(.ultraThinMaterial)
            }
            .padding(.horizontal)
            
            Image("LogoGold")
                .resizable()
                .frame(width: 40, height: 40)
            
            Spacer()
            
            if thankYou {
                Text("🎉 Thank you for your purchase!")
                    .foregroundColor(.green)
                    .padding(.top)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
            
            Button {
                Task {
                    await iapManager.purchase(iapManager.products[0], authModel: authModel, showSheet: $showSheet)
                }
            } label: {
                Text("Upgrade Now")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.yellow)
                    .cornerRadius(12)
                    .shadow(color: Color.yellow, radius: 5)
            }
            .padding(.horizontal)
            
            Button("Restore Purchases") {
                Task {
                    do {
                        try await AppStore.sync()
                        // Success handling (e.g., show confirmation)
                        print("Successfully restored purchases.")
                    } catch {
                        print("Failed to restore purchases: \(error)")
                    }
                }
            }
        }
    }
}
