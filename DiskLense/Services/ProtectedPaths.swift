import Foundation

struct ProtectedPath: Identifiable {
    let id = UUID()
    let path: String
    let description: String
}

@MainActor
class ProtectedPaths: ObservableObject {
    @Published var paths: [ProtectedPath] = []
    
    func loadProtectedPaths() {
        paths = [
            ProtectedPath(path: "/System", description: "System files - DO NOT DELETE"),
            ProtectedPath(path: "/Library", description: "System libraries"),
            ProtectedPath(path: "/Applications", description: "System applications"),
            ProtectedPath(path: "/bin", description: "Binary executables"),
            ProtectedPath(path: "/sbin", description: "System binaries"),
            ProtectedPath(path: "/usr", description: "User utilities")
        ]
    }
    
    func isPathProtected(_ path: String) -> Bool {
        return paths.contains { protectedPath in
            path.hasPrefix(protectedPath.path)
        }
    }
}