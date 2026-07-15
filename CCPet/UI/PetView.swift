import SwiftUI
import Lottie

struct PetView: View {
    @ObservedObject var sessionManager: SessionManager
    var onTap: () -> Void

    @AppStorage("petSize") private var petSize: Double = 120

    private var currentState: PetState {
        sessionManager.activeSession?.state ?? .sleeping
    }

    private var animationName: String {
        switch currentState {
        case .sleeping: return "pet_sleeping"
        case .awake: return "pet_awake"
        case .thinking: return "pet_thinking"
        case .working: return "pet_working"
        case .celebrating: return "pet_celebrating"
        case .error: return "pet_error"
        case .knocking: return "pet_knocking"
        }
    }

    var body: some View {
        LottieView(animation: .named(animationName, bundle: .module))
            .playing(loopMode: .loop)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: petSize, height: petSize)
            .contentShape(Rectangle())
            .onTapGesture { onTap() }
            .id(currentState)
    }
}
