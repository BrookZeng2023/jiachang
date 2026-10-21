import SwiftUI

struct MetadataPill: View {
    let icon: String
    let text: String

    var body: some View {
        Label(text, systemImage: icon)
            .font(.caption.weight(.semibold))
            .foregroundStyle(Color.terracotta)
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(Color.persimmon.opacity(0.10))
            .clipShape(Capsule())
    }
}

struct SectionHeading: View {
    let title: String
    var subtitle: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(title)
                .font(JiachangFont.display(24, weight: .semibold))
                .foregroundStyle(Color.ink)
            if let subtitle {
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(Color.muted)
            }
        }
    }
}

struct RoundToolbarButton<Label: View>: View {
    let action: () -> Void
    @ViewBuilder let label: () -> Label

    var body: some View {
        Button(action: action) { label() }
            .font(.system(size: 18, weight: .semibold))
            .foregroundStyle(Color.ink)
            .frame(width: 42, height: 42)
            .background(.ultraThinMaterial)
            .clipShape(Circle())
            .buttonStyle(PressableCardStyle())
    }
}

struct EmptyKitchenView: View {
    let action: () -> Void
    @Environment(\.appLanguage) private var language

    var body: some View {
        VStack(spacing: 18) {
            ZStack {
                Circle().fill(Color.caramel.opacity(0.17)).frame(width: 136, height: 136)
                Image("LaunchMark").resizable().scaledToFit().frame(width: 88)
            }
            Text(copy(.emptyTitle, language))
                .font(JiachangFont.display(29))
                .foregroundStyle(Color.ink)
            Text(copy(.emptySubtitle, language))
                .font(.subheadline)
                .foregroundStyle(Color.muted)
            Button(copy(.emptyAction, language), action: action)
                .buttonStyle(PrimaryButtonStyle())
                .frame(maxWidth: 260)
        }
        .padding(.horizontal, 24)
    }
}

struct WarmTextField: View {
    let title: String
    @Binding var text: String
    var axis: Axis = .horizontal

    var body: some View {
        TextField(title, text: $text, axis: axis)
            .padding(16)
            .background(Color.paper)
            .clipShape(RoundedRectangle(cornerRadius: 17, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 17, style: .continuous)
                    .stroke(Color.hairline, lineWidth: 1)
            }
    }
}
