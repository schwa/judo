import SwiftUI
import Everything

struct SplashScene: Scene {
    var body: some Scene {
        Window("Judo", id: "judo") {
            SplashView()
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
        .windowManagerRole(.automatic)
    }
}

struct SplashView: View {

    @Environment(AppModel.self)
    var appModel

    @Environment(\.openWindow)
    var openWindow

    @Environment(\.dismissWindow)
    var dismissWindow

    @State
    var selectedRepository: FSPath?

    @State
    var isOpeningRepositoryPresented: Bool = false

    var body: some View {
        HStack {
            VStack {
                Image(nsImage: NSApp.applicationIconImage)
                Text("Welcome to Judo")
                VStack {
                    Button("Open a Repository") {
                        isOpeningRepositoryPresented = true
                    }
                    .fileImporter(isPresented: $isOpeningRepositoryPresented, allowedContentTypes: [.directory], allowsMultipleSelection: false, onCompletion: openRepository)
                    Button("Clone a Repository") {
                    }
                }
                .buttonStyle(.borderless)

                Menu("Recent Repositories") {
                    ForEach(appModel.recentRepositories.reversed(), id: \.self) { path in
                        Button(path.displayName) {
                            openRepository(path)
                        }
                    }
                }
                .menuStyle(.borderlessButton)
                .fixedSize()


                Link("Github", destination: URL(string: "https://github.com/schwa/judo")!)
            }
            .frame(width: 240)
            List(appModel.recentRepositories.reversed(), id: \.self, selection: $selectedRepository) { path in
                HStack {
                    Image(nsImage: path.icon)
                    VStack(alignment: .leading) {
                        Text("\(path.displayName)")
                        Text("\(path)").foregroundStyle(.secondary)
                            .font(.caption)
                    }
                }
                // TODO: This is kinda shit as it imposes a delay and uses semi invisible bg
                .background(Color.white.opacity(0.01))
                .onTapGesture(count: 2) {
                    selectedRepository = path
                    openRepository(path)
                }
                .onTapGesture(count: 1) {
                    selectedRepository = path
                }
            }
        }
        .frame(width: 480, height: 320)
    }

    func openRepository(_ result: Result<[URL], Error>) {
        guard case let .success(urls) = result, !urls.isEmpty else {
            return
        }
        urls.forEach { url in
            openRepository(FSPath(url))
        }
    }

    func openRepository(_ path: FSPath) {
        dismissWindow()
        openWindow(value: path)
    }
}
