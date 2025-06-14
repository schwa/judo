import Everything
import JudoSupport
import SwiftUI
import System

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

    @Environment(\.openDocument)
    var openDocument

    @Environment(\.dismissWindow)
    var dismissWindow

    @State
    private var selectedRepository: FilePath?

    @State
    private var isOpeningRepositoryPresented: Bool = false

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

            let paths = (NSDocumentController.shared.recentDocumentURLs.map(\.filePath)
                            + appModel.recentRepositories.reversed()).uniqued()

            List(selection: $selectedRepository) {
                ForEach(paths, id: \.self) { path in
                    row(for: path)
                }
            }
        }
        .frame(width: 480, height: 320)
    }

    @ViewBuilder
    func row(for path: FilePath) -> some View {
        HStack {
            Image(nsImage: path.icon)
            VStack(alignment: .leading) {
                Text("\(path.displayName)")
                Text(verbatim: path.path).foregroundStyle(.secondary)
                    .font(.caption)
            }
        }
        // TODO: This is kinda shit as it imposes a delay and uses semi invisible bg
        .background(Color.white.opacity(0.01))
        .onTapGesture(count: 2) {
            selectedRepository = path
            //            openRepository(path)
            Task {
                try! await openDocument(at: path.url)
            }
        }
        .onTapGesture(count: 1) {
            selectedRepository = path
        }
    }

    func openRepository(_ result: Result<[URL], Error>) {
        guard case let .success(urls) = result, !urls.isEmpty else {
            return
        }
        urls.forEach { url in
            openRepository(FilePath(url))
        }
    }

    func openRepository(_ path: FilePath) {
        dismissWindow()
        openWindow(value: path)
    }
}

extension URL {
    var filePath: FilePath {
        FilePath(path)
    }
}

extension Array where Element: Hashable {
    func uniqued() -> [Element] {
        var seen = Set<Element>()
        return self.filter { seen.insert($0).inserted }
    }
}
