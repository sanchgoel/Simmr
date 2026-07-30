//
//  SettingsView.swift
//  Simmr
//

import FirebaseAuth
import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var isShowingOnboarding = false
    @ObservedObject private var authManager = AuthenticationManager.shared
    @State private var isShowingLogin = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
                    VStack(alignment: .leading, spacing: Theme.Spacing.xxs) {
                        Text("Account")
                            .font(Theme.Typography.title3)
                            .foregroundStyle(Theme.Colors.textDark)
                        if let email = authManager.currentUser?.email {
                            Text("Signed in as \(email)")
                                .font(Theme.Typography.subheadline)
                                .foregroundStyle(Theme.Colors.textMuted)
                        } else {
                            Text("Not signed in — your recipes and cooking history stay on this device only.")
                                .font(Theme.Typography.subheadline)
                                .foregroundStyle(Theme.Colors.textMuted)
                        }
                    }

                    if authManager.currentUser != nil {
                        Button("Sign Out", role: .destructive) {
                            authManager.signOut()
                        }
                        .buttonStyle(.secondary)
                    } else {
                        Button("Sign In") {
                            isShowingLogin = true
                        }
                        .buttonStyle(.secondary)
                    }

                    Divider()
                        .overlay(Theme.Colors.border)

                    VStack(alignment: .leading, spacing: Theme.Spacing.xxs) {
                        Text("Kitchen Profile")
                            .font(Theme.Typography.title3)
                            .foregroundStyle(Theme.Colors.textDark)
                        Text("Update your cooking habits, dietary needs, and taste preferences.")
                            .font(Theme.Typography.subheadline)
                            .foregroundStyle(Theme.Colors.textMuted)
                    }

                    Button("Edit Kitchen Profile") {
                        isShowingOnboarding = true
                    }
                    .buttonStyle(.secondary)
                }
                .padding(Theme.Spacing.lg)
            }
            .background(Theme.Colors.creamBackground.ignoresSafeArea())
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .fullScreenCover(isPresented: $isShowingOnboarding) {
                OnboardingContainerView(isEditing: true) {
                    isShowingOnboarding = false
                }
            }
            .fullScreenCover(isPresented: $isShowingLogin) {
                LoginView {
                    isShowingLogin = false
                }
            }
        }
    }
}

#Preview {
    SettingsView()
}
