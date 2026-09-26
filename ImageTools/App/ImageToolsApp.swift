import SwiftUI
import RevenueCatUI

@main
struct ImageToolsApp: App {
    init() { Store.shared.configure() }

    var body: some Scene {
        WindowGroup {
            RootView()
                .preferredColorScheme(.dark)
        }
    }
}

struct RootView: View {
    @State private var store = Store.shared
    @State private var path: [Tool] = []
    @State private var showPaywall = false

    var body: some View {
        NavigationStack(path: $path) {
            HomeView(onSelect: open)
                .navigationDestination(for: Tool.self) { tool in
                    switch tool {
                    case .convert: ConvertView()
                    case .size: SizeView()
                    case .compress: CompressView()
                    case .blur: BlurView()
                    }
                }
        }
        .tint(Tokens.Colors.onDark)
        // Every tool is Pro, so the paywall opens by itself as soon as we know the user is locked.
        // It keeps its close button: a reviewer (and a lapsed subscriber) must be able to look around.
        .onChange(of: store.isLocked, initial: true) { _, locked in
            if locked { showPaywall = true }
        }
        .fullScreenCover(isPresented: $showPaywall) {
            PaywallView(displayCloseButton: true)
                .preferredColorScheme(.dark)
        }
    }

    private func open(_ tool: Tool) {
        if store.isLocked {
            showPaywall = true
        } else {
            path.append(tool)
        }
    }
}

enum Tool: String, CaseIterable, Identifiable, Hashable {
    case convert, size, compress, blur
    var id: String { rawValue }
}
