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
            VStack(alignment: .leading, spacing: 16) {
                header
                VStack(spacing: 8) {
                    ForEach(config?.inputs ?? []) { input in
                        InputCard(
                            input: input,
                            isLast: input.id == lastInput,
                            isBusy: input.id == busy
                        ) {
                            Task { await switchTo(input) }
                        }
                    }
                }
                .id(config?.inputs.map(\.id) ?? [])
                .transition(.opacity.combined(with: .offset(y: 4)))
            }
            .padding(16)
            .animation(.easeOut(duration: 0.2), value: config?.inputs.map(\.id) ?? [])
            .frame(maxWidth: 520)
            .frame(maxWidth: .infinity)
        }
        .refreshable { await load() }
        .background(Theme.bg.ignoresSafeArea())
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
            withAnimation(.easeOut(duration: 0.2)) { toast = nil }
        }
    }

    private var header: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 4) {
                Text(verbatim: "monitor-switch")
                    .font(.system(size: 18, weight: .medium))
                Text(verbatim: config?.monitor ?? " ")
                    .font(.system(size: 12).monospacedDigit())
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Button {
                showSettings = true
            } label: {
                Image(systemName: "gearshape.fill")
                    .font(.system(size: 15))
                    .frame(width: 36, height: 36)
                    .background(Theme.chip, in: Circle())
                    .frame(width: 44, height: 44)
                    .contentShape(Circle())
            }
            .foregroundStyle(.secondary)
            .accessibilityLabel("Settings")
        }
    }

    @ViewBuilder private var toastView: some View {
        if let toast {
            Text(toast.text)
                .font(.system(size: 13, weight: .medium).monospacedDigit())
                .foregroundStyle(toast.isError ? Theme.bad : .primary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Theme.toast, in: .rect(cornerRadius: 12))
                .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(Theme.line))
                .padding(16)
                .transition(.opacity.combined(with: .offset(y: 4)))
        }
    }

    private func show(_ text: LocalizedStringKey, isError: Bool = false) {
        withAnimation(.easeOut(duration: 0.2)) { toast = Toast(text: text, isError: isError) }
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
    let isLast: Bool
    let isBusy: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: Theme.symbol(for: input.icon))
                    .font(.system(size: 17))
                    .frame(width: 40, height: 40)
                    .background(Theme.chip, in: .rect(cornerRadius: 10))
                VStack(alignment: .leading, spacing: 2) {
                    Text(verbatim: input.label)
                        .font(.system(size: 15, weight: .medium))
                    Text(verbatim: input.port)
                        .font(.system(size: 12).monospacedDigit())
                        .foregroundStyle(.secondary)
                }
                Spacer(minLength: 0)
                if isBusy {
                    ProgressView().controlSize(.small)
                } else {
                    HStack(spacing: 6) {
                        Circle().fill(Theme.accent).frame(width: 6, height: 6)
                        Text("Last sent")
                    }
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
                    .opacity(isLast ? 1 : 0)
                }
            }
            .padding(12)
        }
        .buttonStyle(CardStyle(isLast: isLast))
        .animation(.easeOut(duration: 0.2), value: isLast)
        .accessibilityLabel(Text(verbatim: "\(input.label), \(input.port)"))
        .accessibilityValue(isLast ? Text("Last sent") : Text(verbatim: ""))
    }
}

/// The web UI's `.card`: white 4% surface, white 8% for the last-sent input, a tiny press.
struct CardStyle: ButtonStyle {
    let isLast: Bool

    func makeBody(configuration: Configuration) -> some View {
        let shape = RoundedRectangle(cornerRadius: 12, style: .continuous)
        configuration.label
            .foregroundStyle(.primary)
            .background(isLast || configuration.isPressed ? Theme.raised : Theme.surface, in: shape)
            .contentShape(shape)
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.easeOut(duration: 0.2), value: configuration.isPressed)
    }
}

#Preview {
    ContentView()
        .preferredColorScheme(.dark)
}
