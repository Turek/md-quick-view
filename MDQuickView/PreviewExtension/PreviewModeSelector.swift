import SwiftUI

// The two viewing modes offered by the preview, in segmented-control order.
enum PreviewMode: Int, CaseIterable, Identifiable {
    case preview
    case raw

    var id: Int { rawValue }

    // The user-facing segment title.
    var title: String {
        switch self {
        case .preview: return "Preview"
        case .raw: return "Raw"
        }
    }
}

// A native segmented control for switching between the two viewing modes.
// Renders as a standard macOS segmented Picker with no custom styling, bound directly to the
// caller's selection.
struct PreviewModeSelector: View {

    // The current selection, owned by the hosting view.
    @Binding var mode: PreviewMode

    var body: some View {
        Picker("View mode", selection: $mode) {
            ForEach(PreviewMode.allCases) { mode in
                Text(mode.title)
                    .accessibilityLabel(mode.title)
                    .tag(mode)
            }
        }
        .pickerStyle(.segmented)
        .labelsHidden()
        .fixedSize()
        .accessibilityLabel("View mode")
    }
}
