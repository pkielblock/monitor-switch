import SwiftUI

struct Toast: Equatable {
    let text: LocalizedStringKey
    let isError: Bool
    let id = UUID()
}

struct ContentView: View {
    @AppStorage("serverURL") private var serverURL = ""
    // The monitor can't report its input, so we show the last one sent from this phone.
    @AppStorage("lastInput") private var lastInput = ""
    @State private var config: MonitorConfig?
    @State private var busy: String?
    @State private var toast: Toast?
    @State private var showSettings = false
    @State private var switched = 0
    @State private var failed = 0

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                header
                VStack(spacing: 14) {
                    ForEach(Array((config?.inputs ?? []).enumerated()), id: \.element.id) { index, input in
                        InputCard(
                            input: input,
                            accent: Theme.accents[index % Theme.accents.count],
                            isLast: input.id == lastInput,
                            isBusy: input.id == busy
                        ) {
                            Task { await switchTo(input) }
                        }
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 28)
            .frame(maxWidth: 520)
            .frame(maxWidth: .infinity)
        }
        .refreshable { await load() }
        .background(Theme.base.ignoresSafeArea())
        .foregroundStyle(Theme.text)
        .overlay(alignment: .bottom) { toastView }
        .sheet(isPresented: $showSettings) { SettingsView(serverURL: $serverURL) }
        .sensoryFeedback(.success, trigger: switched)
        .sensoryFeedback(.error, trigger: failed)
        .task(id: serverURL) {
            if serverURL.isEmpty { showSettings = true } else { await load() }
        }
        .task(id: toast) {
            guard toast != nil else { return }
            try? await Task.sleep(for: .seconds(2.2))
            withAnimation { toast = nil }
        }
    }

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text(verbatim: "monitor-switch")
                    .font(.system(size: 30, weight: .bold))
                    .tracking(-0.6)
                Text(verbatim: config?.monitor ?? " ")
                    .font(.system(size: 14))
                    .foregroundStyle(Theme.muted)
            }
            Spacer()
            Button {
                showSettings = true
            } label: {
                Image(systemName: "gearshape")
                    .font(.system(size: 18, weight: .medium))
                    .frame(width: 44, height: 44)
                    .panel(Circle())
            }
            .foregroundStyle(Theme.muted)
            .accessibilityLabel("Settings")
        }
    }

    @ViewBuilder private var toastView: some View {
        if let toast {
            Text(toast.text)
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(toast.isError ? Theme.love : Theme.text)
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(Theme.surface, in: Capsule())
                .overlay(Capsule().strokeBorder(toast.isError ? Theme.love : Theme.overlay))
                .shadow(color: .black.opacity(0.25), radius: 15, y: 8)
                .padding(.bottom, 24)
                .transition(.move(edge: .bottom).combined(with: .opacity))
        }
    }

    private func show(_ text: LocalizedStringKey, isError: Bool = false) {
        withAnimation(.easeOut(duration: 0.25)) { toast = Toast(text: text, isError: isError) }
    }

    private func load() async {
        guard let api = API(serverURL) else { return }
        do {
            config = try await api.config()
        } catch {
            show("Server unreachable", isError: true)
        }
    }

    private func switchTo(_ input: Input) async {
        guard busy == nil, let api = API(serverURL) else { return }
        busy = input.id
        defer { busy = nil }
        do {
            try await api.switchTo(input.id)
            lastInput = input.id
            switched += 1
            show("Switched to \(input.label)")
        } catch let error as HTTPError {
            failed += 1
            show("Switch failed (\(error.status))", isError: true)
        } catch {
            failed += 1
            show("Server unreachable", isError: true)
        }
    }
}

struct InputCard: View {
    let input: Input
    let accent: Color
    let isLast: Bool
    let isBusy: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: Theme.symbol(for: input.icon))
                    .font(.system(size: 24, weight: .medium))
                    .foregroundStyle(accent)
                    .symbolEffect(.pulse, isActive: isBusy)
                    .frame(width: 56, height: 56)
                    .background(accent.opacity(0.16), in: .rect(cornerRadius: 18, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).strokeBorder(accent.opacity(0.35)))
                VStack(alignment: .leading, spacing: 2) {
                    Text(verbatim: input.label)
                        .font(.system(size: 21, weight: .semibold))
                    Text(verbatim: input.port)
                        .font(.system(size: 14))
                        .foregroundStyle(Theme.muted)
                }
                Spacer(minLength: 0)
                Text("Last sent")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Theme.base)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(accent, in: Capsule())
                    .opacity(isLast ? 1 : 0)
            }
            .padding(20)
        }
        .buttonStyle(CardStyle(accent: accent, isLast: isLast))
        .animation(.easeInOut(duration: 0.2), value: isLast)
        .accessibilityLabel(Text(verbatim: "\(input.label), \(input.port)"))
        .accessibilityValue(isLast ? Text("Last sent") : Text(verbatim: ""))
    }
}

/// The web UI's `.card`: surface panel, overlay fill and slight shrink while pressed,
/// accent border and glow on the last-sent input.
struct CardStyle: ButtonStyle {
    let accent: Color
    let isLast: Bool

    func makeBody(configuration: Configuration) -> some View {
        let shape = RoundedRectangle(cornerRadius: 22, style: .continuous)
        configuration.label
            .background(configuration.isPressed ? Theme.overlay : Theme.surface, in: shape)
            .overlay(shape.strokeBorder(isLast ? accent : Theme.overlay, lineWidth: isLast ? 2 : 1))
            .shadow(color: isLast ? accent.opacity(0.18) : .black.opacity(0.25), radius: 15, y: 8)
            .contentShape(shape)
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

#Preview {
    ContentView()
        .preferredColorScheme(.dark)
}
