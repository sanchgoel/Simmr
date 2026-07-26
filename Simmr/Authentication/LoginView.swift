//
//  LoginView.swift
//  Simmr
//
//  Shown once after onboarding — whether it just finished, or this is the
//  first launch of an already-onboarded install — so people can attach an
//  account before continuing. Skippable, matching onboarding's own Skip
//  button, since the rest of the app works fully signed out for now.
//
//  Both provider buttons use Simmr's own .primary button style rather than
//  either SDK's stock control, so they read as part of the app instead of a
//  bolted-on third-party widget — AuthenticationManager owns the whole
//  ASAuthorizationController/GIDSignIn flow so a plain Button can drive it.
//  The Google mark is Google's official asset (developers.google.com/
//  identity/images/g-logo.png); Apple's own SF Symbol covers its logo.
//

import SwiftUI

struct LoginView: View {
    var onComplete: () -> Void

    @ObservedObject private var authManager = AuthenticationManager.shared
    @State private var errorMessage: String?
    @State private var isSigningIn = false

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
            Spacer()

            VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                Text("Sign in to Simmr")
                    .font(Theme.Typography.largeTitle)
                    .foregroundStyle(Theme.Colors.textDark)

                Text("Signing in keeps your recipes and cooking history backed up. You can always do this later from Settings.")
                    .font(Theme.Typography.body)
                    .foregroundStyle(Theme.Colors.textMuted)
            }

            if let errorMessage {
                Text(errorMessage)
                    .font(Theme.Typography.footnote)
                    .foregroundStyle(Theme.Colors.coral)
            }

            Spacer()
            Spacer()

            VStack(spacing: Theme.Spacing.sm) {
                providerButton(title: "Continue with Apple", action: authManager.signInWithApple) {
                    Image(systemName: "apple.logo")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(Theme.Colors.textDark)
                }

                providerButton(title: "Continue with Google", action: authManager.signInWithGoogle) {
                    Image("GoogleLogo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 18, height: 18)
                }

                Button("Skip for now", action: onComplete)
                    .font(Theme.Typography.footnote.weight(.semibold))
                    .foregroundStyle(Theme.Colors.textMuted)
                    .padding(.top, Theme.Spacing.xs)
                    .frame(maxWidth: .infinity)
            }
        }
        .padding(Theme.Spacing.lg)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .background(Theme.Colors.creamBackground)
        .disabled(isSigningIn)
        .overlay {
            if isSigningIn {
                Color.black.opacity(0.15)
                    .ignoresSafeArea()
                    .transition(.opacity)
                ProgressView()
                    .tint(Theme.Colors.textDark)
                    .scaleEffect(1.3)
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.2), value: isSigningIn)
    }

    private func providerButton(
        title: String,
        action: @escaping () async throws -> Void,
        @ViewBuilder icon: () -> some View
    ) -> some View {
        Button {
            Task {
                isSigningIn = true
                errorMessage = nil
                defer { isSigningIn = false }
                do {
                    try await action()
                    onComplete()
                } catch {
                    errorMessage = (error as? LocalizedError)?.errorDescription ?? "Something went wrong. Please try again."
                }
            }
        } label: {
            HStack(spacing: Theme.Spacing.sm) {
                icon()
                Text(title)
            }
        }
        .buttonStyle(.secondary)
    }
}

#Preview {
    LoginView {}
}
