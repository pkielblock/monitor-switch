import SwiftUI

struct SettingsView: View {
    @Binding var serverURL: String
    @AppStorage("language") private var language = "en"
    @State private var draft = ""
    @Environment(\.dismiss) private var dismiss

    // Language names are shown in their own language.
    private static let languages = [("en", "English"), ("pt-BR", "Português")]

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Server URL", text: $draft, prompt: Text(verbatim: "https://monitor-switch.example.com"))
                        .keyboardType(.URL)
                        .textContentType(.URL)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .submitLabel(.done)
                        .onSubmit(save)
                } header: {
                    Text("Server URL")
                } footer: {
                    Text("Address of your monitor-switch server, as you would open it in Safari. A LAN address such as http://192.168.1.10:7580 also works")
                }
                .listRowBackground(Theme.surface)

                Section("Language") {
                    Picker("Language", selection: $language) {
                        ForEach(Self.languages, id: \.0) { code, name in
                            Text(verbatim: name).tag(code)
                        }
                    }
                    .pickerStyle(.segmented)
                    .labelsHidden()
                }
                .listRowBackground(Theme.surface)
            }
            .scrollContentBackground(.hidden)
            .background(Theme.bg)
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .disabled(serverURL.isEmpty)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save", action: save)
                        .disabled(API(draft) == nil)
                }
            }
        }
        .presentationBackground(Theme.bg)
        .interactiveDismissDisabled(serverURL.isEmpty)
        .onAppear { draft = serverURL }
    }

    private func save() {
        guard let api = API(draft) else { return }
        serverURL = api.base.absoluteString
        dismiss()
    }
}
