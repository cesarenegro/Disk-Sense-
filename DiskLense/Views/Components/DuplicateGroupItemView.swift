import SwiftUI
import UniformTypeIdentifiers

struct DuplicateGroupItemView: View {
    let index: Int
    let group: [URL]
    let dup: DuplicateFinder
    @Binding var selectedFiles: Set<URL>

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(groupTitle)
                    .font(.headline)
                    .foregroundColor(.white)
                Spacer()
                Text("\(group.count) files")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.65))
            }

            ForEach(group, id: \.path) { file in
                HStack {
                    SelectionCheckbox(isSelected: binding(for: file))

                    Image(systemName: iconName(for: file))
                        .foregroundColor(.white.opacity(0.7))
                    Text(file.lastPathComponent)
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.85))
                        .lineLimit(1)
                    Spacer()
                }
            }
        }
        .padding()
        .background(Color.white.opacity(0.06))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(Color.white.opacity(0.10), lineWidth: 1)
        )
        .cornerRadius(12)
    }

    private var groupTitle: String {
        guard let first = group.first else { return "Group \(index + 1)" }
        let ext = first.pathExtension.uppercased()
        let category = categoryName(for: first)
        return ext.isEmpty ? category : "\(category) (\(ext))"
    }

    private func binding(for file: URL) -> Binding<Bool> {
        Binding(
            get: { selectedFiles.contains(file) },
            set: { isSelected in
                if isSelected {
                    selectedFiles.insert(file)
                } else {
                    selectedFiles.remove(file)
                }
            }
        )
    }

    private func categoryName(for file: URL) -> String {
        let ext = file.pathExtension.lowercased()
        guard let type = UTType(filenameExtension: ext) else { return "Other" }

        if type.conforms(to: .image) { return "Images" }
        if type.conforms(to: .movie) || type.conforms(to: .video) { return "Movies" }
        if type.conforms(to: .audio) { return "Music" }
        if type.conforms(to: .pdf) || type.conforms(to: .text) { return "Documents" }
        if type.conforms(to: .archive) { return "Archives" }

        return "Other"
    }

    private func iconName(for file: URL) -> String {
        let ext = file.pathExtension.lowercased()
        guard let type = UTType(filenameExtension: ext) else { return "doc" }

        if type.conforms(to: .image) { return "photo" }
        if type.conforms(to: .movie) || type.conforms(to: .video) { return "film" }
        if type.conforms(to: .audio) { return "music.note" }
        if type.conforms(to: .pdf) { return "doc.richtext" }
        if type.conforms(to: .archive) { return "archivebox" }

        return "doc"
    }
}
