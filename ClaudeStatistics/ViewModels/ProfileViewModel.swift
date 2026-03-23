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
            // Token might be expired — try refreshing via CLI and retry
            let refreshed = await UsageAPIService.shared.refreshToken()
            if refreshed {
                userProfile = try? await UsageAPIService.shared.fetchProfile()
            }
        }
        profileLoading = false
    }
}
