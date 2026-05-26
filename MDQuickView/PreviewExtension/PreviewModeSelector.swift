import SwiftUI

// The three viewing modes offered by the preview, in segmented-control order.
enum PreviewMode: Int, CaseIterable, Identifiable {
    case preview
    case raw
    case sideBySide

    var id: Int { rawValue }

    // The user-facing segment title.
    var title: String {
        switch self {
        case .preview: return "Preview"
        case .raw: return "Raw"
        case .sideBySide: return "Side-by-side"
        }
    }
}

// A native segmented control for switching between the three viewing modes.
// Renders as a standard macOS segmented Picker with no custom styling and reports
// every selection change to the hosting controller.
struct PreviewModeSelector: View {

    // Defaults to Preview, matching the required initial selection.
    @State private var mode: PreviewMode = .preview

    // Invoked on the main actor whenever the user picks a different mode.
    let onModeChange: @MainActor (PreviewMode) -> Void

    var body: some View {
        Picker("View mode", selection: $mode) {
            ForEach(PreviewMode.allCases) { mode in
                Text(mode.title).tag(mode)
            }
        }
        .pickerStyle(.segmented)
        .labelsHidden()
        .fixedSize()
        .onChange(of: mode) { _, newValue in
            onModeChange(newValue)
        }
    }
}
