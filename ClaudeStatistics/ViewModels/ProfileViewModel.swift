import Foundation

@MainActor
final class ProfileViewModel: ObservableObject {
    @Published var userProfile: UserProfile?
    @Published var profileLoading = false

    init() {
        Task { @MainActor in
            await self.loadProfile()
        }
    }

    func loadProfile() async {
        guard userProfile == nil, !profileLoading else { return }
        guard CredentialService.shared.getAccessToken() != nil else { return }
        profileLoading = true
        do {
            userProfile = try await UsageAPIService.shared.fetchProfile()
        } catch {
            // Silent fail — settings will show token-only fallback
        }
        profileLoading = false
    }
}
