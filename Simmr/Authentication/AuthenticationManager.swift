//
//  AuthenticationManager.swift
//  Simmr
//
//  Thin wrapper around FirebaseAuth for the two sign-in methods Simmr
//  supports: Sign in with Apple (native ASAuthorizationController, exchanged
//  for a Firebase credential) and Google (GoogleSignIn SDK, same exchange).
//  Both are driven from custom-styled buttons in LoginView rather than
//  either provider's stock control, so this owns the whole flow for each
//  instead of just reacting to a native button's callback.
//

import AuthenticationServices
import Combine
import CryptoKit
import FirebaseAuth
import FirebaseCore
import Foundation
import GoogleSignIn
import UIKit

@MainActor
final class AuthenticationManager: NSObject, ObservableObject {
    static let shared = AuthenticationManager()

    @Published private(set) var currentUser: User?

    /// False until a real GoogleService-Info.plist is present and
    /// FirebaseApp.configure() has run — sign-in calls fail with a clear
    /// error instead of crashing the app before the Firebase project is
    /// wired in.
    private(set) var isConfigured = false

    private var appleSignInContinuation: CheckedContinuation<ASAuthorizationAppleIDCredential, Error>?
    private var currentAppleNonce: String?

    private override init() {
        super.init()
        if FirebaseApp.app() == nil, Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist") != nil {
            FirebaseApp.configure()
        }
        isConfigured = FirebaseApp.app() != nil
        currentUser = isConfigured ? Auth.auth().currentUser : nil

        // GoogleSignIn doesn't pick up Firebase's GoogleService-Info.plist
        // automatically — without this, signIn(withPresenting:) crashes
        // (GoogleSignIn asserts a non-nil configuration internally).
        if let clientID = FirebaseApp.app()?.options.clientID {
            GIDSignIn.sharedInstance.configuration = GIDConfiguration(clientID: clientID)
        }

        // Firebase Auth restores a signed-in session from the Keychain on
        // its own, without going through signInWithApple()/signInWithGoogle()
        // — so a launch that's already signed in needs its own sync kick,
        // otherwise anything saved locally since the last real sign-in call
        // (or the user doc itself, on a device that's never run
        // performInitialSync before) never reaches Firestore.
        if currentUser != nil {
            Task { await FirestoreSyncManager.shared.performInitialSync() }
        }
    }

    enum AuthError: LocalizedError {
        case notConfigured
        case cancelled
        case missingCredential
        case noPresentingWindow

        var errorDescription: String? {
            switch self {
            case .notConfigured:
                return "Sign-in isn't set up yet."
            case .cancelled:
                return "Sign-in was cancelled."
            case .missingCredential:
                return "Couldn't complete sign-in. Please try again."
            case .noPresentingWindow:
                return "Couldn't present the sign-in screen. Please try again."
            }
        }
    }

    func signOut() {
        try? Auth.auth().signOut()
        GIDSignIn.sharedInstance.signOut()
        currentUser = nil
    }

    // MARK: - Google

    func signInWithGoogle() async throws {
        guard isConfigured else { throw AuthError.notConfigured }
        guard let presentingViewController = Self.topViewController() else {
            throw AuthError.noPresentingWindow
        }

        let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: presentingViewController)
        guard let idToken = result.user.idToken?.tokenString else {
            throw AuthError.missingCredential
        }

        let credential = GoogleAuthProvider.credential(withIDToken: idToken, accessToken: result.user.accessToken.tokenString)
        let authResult = try await Auth.auth().signIn(with: credential)
        await FirestoreSyncManager.shared.handleSignIn(user: authResult.user)
        currentUser = authResult.user
    }

    // MARK: - Apple

    func signInWithApple() async throws {
        guard isConfigured else { throw AuthError.notConfigured }

        let nonce = Self.randomNonceString()
        currentAppleNonce = nonce

        let request = ASAuthorizationAppleIDProvider().createRequest()
        request.requestedScopes = [.fullName, .email]
        request.nonce = Self.sha256(nonce)

        let controller = ASAuthorizationController(authorizationRequests: [request])
        controller.delegate = self
        controller.presentationContextProvider = self

        let credential = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<ASAuthorizationAppleIDCredential, Error>) in
            appleSignInContinuation = continuation
            controller.performRequests()
        }

        guard let identityTokenData = credential.identityToken,
              let identityToken = String(data: identityTokenData, encoding: .utf8)
        else {
            throw AuthError.missingCredential
        }

        let firebaseCredential = OAuthProvider.credential(providerID: .apple, idToken: identityToken, rawNonce: nonce)
        let authResult = try await Auth.auth().signIn(with: firebaseCredential)
        await FirestoreSyncManager.shared.handleSignIn(user: authResult.user)
        currentUser = authResult.user
    }
}

extension AuthenticationManager: ASAuthorizationControllerDelegate {
    nonisolated func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        Task { @MainActor in
            guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential else {
                appleSignInContinuation?.resume(throwing: AuthError.missingCredential)
                appleSignInContinuation = nil
                return
            }
            appleSignInContinuation?.resume(returning: credential)
            appleSignInContinuation = nil
        }
    }

    nonisolated func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        Task { @MainActor in
            if let authError = error as? ASAuthorizationError, authError.code == .canceled {
                appleSignInContinuation?.resume(throwing: AuthError.cancelled)
            } else {
                appleSignInContinuation?.resume(throwing: error)
            }
            appleSignInContinuation = nil
        }
    }
}

extension AuthenticationManager: ASAuthorizationControllerPresentationContextProviding {
    nonisolated func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        MainActor.assumeIsolated {
            Self.keyWindow() ?? ASPresentationAnchor()
        }
    }
}

// MARK: - Helpers

private extension AuthenticationManager {
    static func keyWindow() -> UIWindow? {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first { $0.isKeyWindow }
    }

    static func topViewController() -> UIViewController? {
        guard let root = keyWindow()?.rootViewController else { return nil }
        var top = root
        while let presented = top.presentedViewController {
            top = presented
        }
        return top
    }

    static func randomNonceString(length: Int = 32) -> String {
        precondition(length > 0)
        let charset: [Character] = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        var result = ""
        var remainingLength = length

        while remainingLength > 0 {
            let randoms: [UInt8] = (0..<16).map { _ in UInt8.random(in: 0...255) }
            for random in randoms {
                if remainingLength == 0 { break }
                if random < charset.count {
                    result.append(charset[Int(random)])
                    remainingLength -= 1
                }
            }
        }
        return result
    }

    static func sha256(_ input: String) -> String {
        let hashed = SHA256.hash(data: Data(input.utf8))
        return hashed.compactMap { String(format: "%02x", $0) }.joined()
    }
}
