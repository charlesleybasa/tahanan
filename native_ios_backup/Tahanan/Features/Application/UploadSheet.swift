import SwiftUI
import UniformTypeIdentifiers

/// Upload a requirement with the camera or Files: picker → progress → "Submitted for review".
struct UploadSheet: View {
    @Environment(AppState.self) private var state
    let requirementId: String
    let onClose: () -> Void

    @State private var step = 0
    @State private var filename = "IMG_2048.jpg"
    @State private var showCamera = false
    @State private var showFiles = false
    @State private var progress = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Upload requirement").eyebrow()
            Text(state.requirement(requirementId)?.name ?? "").h1(26).padding(.top, 8)

            Group {
                switch step {
                case 0: chooser
                case 1: uploading
                default: done
                }
            }
            .id(step)
            .transition(.fadeIn)
        }
        .fullScreenCover(isPresented: $showCamera) {
            CameraCapture { image in
                showCamera = false
                if let image { start(name: "IMG_\(Int.random(in: 1000...9999)).jpg", data: image.jpegData(compressionQuality: 0.8)) }
            }
            .ignoresSafeArea()
        }
        .fileImporter(isPresented: $showFiles, allowedContentTypes: [.pdf, .image]) { result in
            if case let .success(url) = result {
                let scoped = url.startAccessingSecurityScopedResource()
                let data = try? Data(contentsOf: url)
                if scoped { url.stopAccessingSecurityScopedResource() }
                start(name: url.lastPathComponent, data: data)
            }
        }
    }

    private var chooser: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Clear photo or PDF, all four corners visible. Max 10 MB.").mutedBody(14).padding(.top, 8)
            HStack(spacing: 10) {
                option(.camera, "Take a photo") {
                    if CameraCapture.isAvailable { showCamera = true } else { start(name: filename, data: nil) }
                }
                option(.document, "Choose a file") { showFiles = true }
            }
            .padding(.top, 18)
        }
    }

    private func option(_ icon: Icon, _ title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 10) {
                IconView(icon, size: 26).foregroundStyle(Palette.yellow)
                Text(title).font(Typo.manrope(14, .extrabold)).foregroundStyle(Palette.text)
            }
            .frame(maxWidth: .infinity).frame(height: 110)
            .background(RoundedRectangle(cornerRadius: 22).fill(Color.white(0.05)))
            .overlay(RoundedRectangle(cornerRadius: 22).strokeBorder(Color.white(0.14), lineWidth: 1))
        }
        .pressable()
    }

    private var uploading: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 12) {
                IconTile(icon: .image, tint: Palette.yellow, background: Palette.yellow.opacity(0.16))
                VStack(alignment: .leading, spacing: 8) {
                    Text(filename).font(Typo.manrope(14, .extrabold)).foregroundStyle(Palette.text).lineLimit(1)
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule().fill(Color.white(0.1))
                            Capsule().fill(Palette.yellow).frame(width: progress ? geo.size.width : 0)
                        }
                    }
                    .frame(height: 6)
                }
            }
            .padding(14)
            .glass(18)
            Text("Uploading securely…").mutedBody(13).padding(.top, 12)
        }
        .padding(.top, 18)
        .onAppear {
            // .upbar: 1.6s cubic-bezier(.4,0,.2,1)
            withAnimation(.timingCurve(0.4, 0, 0.2, 1, duration: 1.6)) { progress = true }
        }
    }

    private var done: some View {
        VStack(spacing: 0) {
            Circle().fill(Palette.blue).frame(width: 84, height: 84)
                .overlay(IconView(.check, size: 40).foregroundStyle(.white))
                .pop()
            Text("Submitted for review").font(Typo.manrope(16, .extrabold)).foregroundStyle(Palette.text).padding(.top, 16)
            Text("We’ll notify you once it’s reviewed and accepted.").mutedBody(14).multilineTextAlignment(.center).padding(.top, 6)
            PrimaryButton("Done", icon: nil, action: onClose).padding(.top, 20)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 14)
    }

    private func start(name: String, data: Data?) {
        filename = name
        withAnimation(.easeInOut(duration: 0.4)) { step = 1 }
        Task {
            _ = try? await state.repos.requirements.upload(requirementId: requirementId, fileData: data, filename: name)
            try? await Task.sleep(nanoseconds: 1_800_000_000)
            state.markSubmitted(requirementId)
            withAnimation(.easeInOut(duration: 0.4)) { step = 2 }
        }
    }
}
