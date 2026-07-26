//
//  FirestoreSyncManager.swift
//  Simmr
//
//  Mirrors local data up to Firestore once someone's signed in. Local
//  storage (UserDefaults) remains the source of truth for everything —
//  the app must keep working fully offline and fully signed-out — so every
//  sync call here is best-effort and fire-and-forget: a failed write just
//  means the next local save tries again, never a user-facing error.
//
//  Firestore layout:
//    users/{uid}                                — email/displayName/timestamps
//    users/{uid}/profile/kitchenProfile          — onboarding answers
//    users/{uid}/cookingSessions/{sessionID}     — recipes + cooking progress
//

import FirebaseAuth
import FirebaseFirestore
import Foundation

@MainActor
final class FirestoreSyncManager {
    static let shared = FirestoreSyncManager()

    private init() {}

    private var db: Firestore? {
        AuthenticationManager.shared.isConfigured ? Firestore.firestore() : nil
    }

    private var userID: String? {
        AuthenticationManager.shared.currentUser?.uid
    }

    // MARK: - User details

    /// Creates the user doc on first sign-in, refreshes it on every
    /// subsequent one — `createdAt` only gets set once since it's checked
    /// against the existing document first.
    ///
    /// Takes `user` explicitly rather than reading
    /// `AuthenticationManager.shared.currentUser` — see `handleSignIn`'s
    /// comment for why that ambient property can't be trusted during the
    /// sign-in window itself.
    func syncUserDetails(user: User) async {
        guard let db else { return }
        let ref = db.collection("users").document(user.uid)

        var data: [String: Any] = [
            "email": user.email as Any,
            "displayName": user.displayName as Any,
            "lastSignInAt": FieldValue.serverTimestamp(),
        ]

        let existing = try? await ref.getDocument()
        if existing?.exists != true {
            data["createdAt"] = FieldValue.serverTimestamp()
        }

        try? await ref.setData(data, merge: true)
    }

    // MARK: - Kitchen Profile

    /// `userID` defaults to the ambient signed-in user for the common case
    /// (called from a local save, well after sign-in has settled) — pass it
    /// explicitly only from the sign-in path itself, where that ambient
    /// value isn't safe to read yet.
    func syncKitchenProfile(_ profile: KitchenProfile, userID: String? = nil) async {
        guard let db, let userID = userID ?? self.userID else { return }
        try? db.collection("users").document(userID)
            .collection("profile").document("kitchenProfile")
            .setData(from: profile, merge: false)
    }

    // MARK: - Cooking Sessions

    func syncCookingSession(_ session: CookingSession, userID: String? = nil) async {
        guard let db, let userID = userID ?? self.userID else { return }
        try? db.collection("users").document(userID)
            .collection("cookingSessions").document(session.id.uuidString)
            .setData(from: session, merge: false)
    }

    func deleteCookingSession(id: UUID) async {
        guard let db, let userID else { return }
        try? await db.collection("users").document(userID)
            .collection("cookingSessions").document(id.uuidString)
            .delete()
    }

    // MARK: - Sign-in

    /// Called right after an interactive sign-in (LoginView's Apple/Google
    /// buttons), with the just-authenticated `user` passed explicitly —
    /// AuthenticationManager deliberately holds off setting its own
    /// `@Published currentUser` until this whole call returns. RootView
    /// switches from LoginView to HomeView the instant `currentUser` goes
    /// non-nil, so setting it any earlier would let HomeView mount and read
    /// local storage before the restore below has written anything to it —
    /// exactly the race that caused a fresh sign-in to land on an empty
    /// Home despite Firestore already having data.
    ///
    /// Restores first — a fresh install has nothing local yet, so without
    /// this step existing Firestore data would sit there unpulled until
    /// performInitialSync's guards (which only ever push, never pull) pass
    /// right over it — then pushes, so the user doc/timestamps and anything
    /// genuinely new on this device still make it up.
    func handleSignIn(user: User) async {
        await restoreFromFirestoreIfNeeded(userID: user.uid)
        await performInitialSync(user: user)
    }

    // MARK: - Initial push

    /// Called once right after a successful sign-in — pushes whatever was
    /// already on this device up to Firestore, so signing in on a fresh
    /// Firebase project (or after using the app signed-out for a while)
    /// doesn't leave existing local data stranded until its next edit.
    /// `user` defaults to the ambient signed-in user (the already-signed-in-
    /// at-launch path in AuthenticationManager.init() has no race to avoid);
    /// `handleSignIn` passes it explicitly for the same reason noted there.
    func performInitialSync(user: User? = nil) async {
        guard let user = user ?? AuthenticationManager.shared.currentUser else { return }
        await syncUserDetails(user: user)

        if let profile = UserDefaultsKitchenProfileStore().load() {
            await syncKitchenProfile(profile, userID: user.uid)
        }

        if let sessions = try? await LocalCookingSessionRepository().fetchAllSessions() {
            for session in sessions {
                await syncCookingSession(session, userID: user.uid)
            }
        }
    }

    // MARK: - Restore (pull down)

    /// Called at launch, before RootView decides whether to show onboarding
    /// — a signed-in account with empty local storage (a fresh install, or
    /// a reinstall) otherwise looks like starting over even though
    /// everything is sitting in Firestore. Only pulls whichever piece is
    /// actually missing locally, so it never clobbers data that was
    /// created on this device but hasn't synced up yet.
    ///
    /// `userID` defaults to the ambient signed-in user (RootView's launch
    /// `.task` only calls this once `authManager.currentUser != nil`, so
    /// there's no race there); `handleSignIn` passes it explicitly since
    /// that property isn't set yet during an interactive sign-in.
    ///
    /// Unlike the push methods above, every step here reports through
    /// APIDebugLogStore (shake to view) — this pull runs exactly once at a
    /// moment (fresh install / fresh sign-in) where nothing else in the app
    /// gives a signal if it silently comes back empty, so a swallowed `try?`
    /// here would be much harder to diagnose than a swallowed push error.
    func restoreFromFirestoreIfNeeded(userID: String? = nil) async {
        let startedAt = Date()
        var lines: [String] = []
        var hadError = false
        defer {
            APIDebugLogStore.shared.log(APICallLog(
                timestamp: startedAt,
                endpoint: "Firestore restore",
                model: nil,
                requestBody: nil,
                statusCode: nil,
                responseBody: lines.joined(separator: "\n"),
                error: hadError ? "See details" : nil,
                duration: Date().timeIntervalSince(startedAt)
            ))
        }

        guard let db else {
            lines.append("Skipped — Firestore not configured")
            return
        }
        guard let userID = userID ?? self.userID else {
            lines.append("Skipped — no signed-in user")
            return
        }
        lines.append("uid: \(userID)")

        let profileStore = UserDefaultsKitchenProfileStore()
        if profileStore.load() == nil {
            do {
                let snapshot = try await db.collection("users").document(userID)
                    .collection("profile").document("kitchenProfile")
                    .getDocument()
                if snapshot.exists {
                    let profile = try snapshot.data(as: KitchenProfile.self)
                    profileStore.save(profile)
                    lines.append("Profile: restored")
                } else {
                    lines.append("Profile: no document at users/\(userID)/profile/kitchenProfile")
                }
            } catch {
                hadError = true
                lines.append("Profile: failed — \(error)")
            }
        } else {
            lines.append("Profile: skipped, already present locally")
        }

        let sessionRepository = LocalCookingSessionRepository()
        let localSessions = (try? await sessionRepository.fetchAllSessions()) ?? []
        if localSessions.isEmpty {
            do {
                let snapshot = try await db.collection("users").document(userID)
                    .collection("cookingSessions")
                    .getDocuments()
                lines.append("Sessions: found \(snapshot.documents.count) document(s)")
                var restoredCount = 0
                for document in snapshot.documents {
                    do {
                        let session = try document.data(as: CookingSession.self)
                        try await sessionRepository.save(session)
                        restoredCount += 1
                    } catch {
                        hadError = true
                        lines.append("Sessions: failed for \(document.documentID) — \(error)")
                    }
                }
                lines.append("Sessions: restored \(restoredCount)")
            } catch {
                hadError = true
                lines.append("Sessions: fetch failed — \(error)")
            }
        } else {
            lines.append("Sessions: skipped, \(localSessions.count) already present locally")
        }
    }
}
