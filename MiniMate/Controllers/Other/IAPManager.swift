//
//  IAPManager.swift
//  MiniMate
//
//  Created by Garrett Butchko on 6/2/25.
//
import StoreKit
import SwiftUI

class IAPManager: ObservableObject {
   @Published var products: [Product] = []
   private var isInitialized = false
   
   init() {
       // Lightweight init - defer heavy operations
   }
   
   // Call this after UI is rendered
   func initialize() async {
       print("Retrieving products")
       guard !isInitialized else { return }
       isInitialized = true
       
       await self.retrieveProducts()

       // Listen in the background so init doesn't block forever.
       Task { [weak self] in
           await self?.listenForTransactions()
       }
   }
   
    @MainActor
    func retrieveProducts() async {
        do {
            let productIDs = ["com.minimate.pro"]
            let fetchedProducts = try await Product.products(for: productIDs)
            self.products = fetchedProducts
            print("Products retrieved: \(fetchedProducts.map { $0.displayName })")
        } catch {
            print("Failed to fetch products: \(error)")
        }
    }
    
    func purchase(_ product: Product, authModel: AuthViewModel, showSheet: Binding<Bool>) async -> Bool {
        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                let transaction = try self.verifyPurchase(verification)
                await transaction.finish()
                
                await MainActor.run {
                    withAnimation {
                        authModel.userModel?.isPro = true
                        showSheet.wrappedValue = false
                    }
                }
                
                if let userModel = authModel.userModel {
                    UserRepository().saveRemote(id: userModel.googleId, userModel: userModel) { completed in
                        print("Updated online user")
                    }
                }
                return true
                
            case .userCancelled, .pending:
                return false
            @unknown default:
                return false
            }
        } catch {
            print("Purchase failed: \(error)")
            return false
        }
    }
    
    func listenForTransactions() async {
        for await update in Transaction.updates {
            do {
                let transaction = try self.verifyPurchase(update)
                // Update your app state here (e.g., unlock premium features)
                await transaction.finish()
                print("Transaction processed: \(transaction.productID)")
            } catch {
                print("Transaction verification failed: \(error)")
            }
        }
    }
    
   private func verifyPurchase(_ verification: VerificationResult<StoreKit.Transaction>) throws -> StoreKit.Transaction {
       switch verification {
       case .unverified:
           throw NSError(domain: "Verification failed", code: 1, userInfo: nil)
       case .verified(let transaction):
           return transaction
       }
   }
    
    func isPurchasedPro(authModel: AuthViewModel) async {
        var hasPro = false

        for await result in Transaction.currentEntitlements {
            if case .verified(let transaction) = result,
               transaction.productID == "com.minimate.pro" {
                hasPro = true
                break
            }
        }
        withAnimation {
            authModel.userModel?.isPro = hasPro
        }
    }
}
