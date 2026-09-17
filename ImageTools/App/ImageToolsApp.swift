import SwiftUI

@main
struct ImageToolsApp: App {
    var body: some Scene {
        WindowGroup {
            RootView()
                .preferredColorScheme(.dark)
        }
    }
}

struct RootView: View {
    var body: some View {
        NavigationStack {
            HomeView()
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
    }
}

enum Tool: String, CaseIterable, Identifiable, Hashable {
    case convert, size, compress, blur
    var id: String { rawValue }
}
