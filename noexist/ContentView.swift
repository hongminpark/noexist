//

import SwiftUI
import SceneKit

import SwiftUI
import SceneKit
import AVFoundation
import SwiftVideoGenerator

struct ContentView: View {
    let usdzFile = "Balenciaga_Defender"
    @State private var captureSnapshot = false
    @State private var record = false
    @StateObject private var sceneHolder = SceneHolder()
    @State private var frameCaptureManager: FrameCaptureManager?
    @State private var isCapturing = false

    var body: some View {
        VStack {
            SceneKitView(fileName: usdzFile, captureSnapshot: $captureSnapshot, sceneHolder: sceneHolder)
            .frame(height: 300)
            .padding()
            .cornerRadius(12)
            Button("Capture Snapshot") {
                captureSnapshot = true
            }
            .padding()
            .background(.black)
            .foregroundColor(.white)
            Button(isCapturing ? "Stop" : "Record") {
                if isCapturing {
                    frameCaptureManager?.stopCapture()
                    isCapturing = false
                } else {
                    isCapturing = true
                    if let scnView = sceneHolder.scnView, let scene = scnView.scene {
                        self.frameCaptureManager = FrameCaptureManager(scene: scene, view: scnView)
                        self.frameCaptureManager?.startCapture()
                    }
                }
                captureSnapshot = true
            }
            .padding()
            .background(.black)
            .foregroundColor(.white)
        }
    }
}

struct SceneKitView: UIViewRepresentable {
    let fileName: String
    @Binding var captureSnapshot: Bool
    var sceneHolder: SceneHolder

    func makeUIView(context: Context) -> SCNView {
        let sceneView = SCNView()
        sceneView.autoenablesDefaultLighting = true
        sceneView.allowsCameraControl = true
        sceneView.backgroundColor = .clear

        if let url = Bundle.main.url(forResource: fileName, withExtension: "usdz"),
           let scene = try? SCNScene(url: url, options: nil) {
            let rootNode = scene.rootNode

            rootNode.eulerAngles = SCNVector3(0, 0, 0)
            rootNode.position = SCNVector3(0, 0, 0)
            rootNode.scale = SCNVector3(1, 1, 1)
            let rotation = SCNAction.rotateBy(x: 0, y: 0, z: CGFloat.pi * 2, duration: 10)
            let repeatRotation = SCNAction.repeatForever(rotation)
            rootNode.runAction(repeatRotation)
            sceneView.scene = scene
        }
        sceneHolder.scnView = sceneView
        return sceneView
    }
    
    func updateUIView(_ uiView: SCNView, context: Context) {
        if captureSnapshot {
            let image = uiView.snapshot()
            if let pngData = image.pngData(), let pngImage = UIImage(data: pngData) {
                UIImageWriteToSavedPhotosAlbum(pngImage, nil, nil, nil)
            }
            captureSnapshot = false
        }
    }
}

class SceneHolder: ObservableObject {
    var scnView: SCNView?
}

class FrameCaptureManager {
    private var scnRenderer: SCNRenderer
    private var displayLink: CADisplayLink?
    private var isCapturing = false
    private var frameCount = 0
    private var framesDirectory: URL?

    init(scene: SCNScene, view: SCNView) {
        self.scnRenderer = SCNRenderer(device: nil, options: nil)
        self.scnRenderer.scene = scene
        self.scnRenderer.autoenablesDefaultLighting = true
        self.scnRenderer.pointOfView = view.pointOfView
    }

    func startCapture() {
        isCapturing = true
        displayLink = CADisplayLink(target: self, selector: #selector(renderAndCapture))
        displayLink?.add(to: .current, forMode: .common)
        createFramesDirectory()
    }

    func stopCapture() {
        displayLink?.invalidate()
        isCapturing = false
    }

    @objc private func renderAndCapture() {
        if isCapturing {
            let image = scnRenderer.snapshot(atTime: CACurrentMediaTime(), with: CGSize(width: 1080, height: 1080), antialiasingMode: .none)
            if let data = image.pngData() {
                saveFrame(data: data)
            }
            if frameCount == 60 {
                generateVideoFromImages()
                isCapturing = false
            }
        }
    }
    
    private func createFramesDirectory() {
        let tempDir = FileManager.default.temporaryDirectory
        let directoryName = UUID().uuidString
        let directoryURL = tempDir.appendingPathComponent(directoryName)
        do {
            try FileManager.default.createDirectory(at: directoryURL, withIntermediateDirectories: true, attributes: nil)
            framesDirectory = directoryURL
        } catch {
            print("Error creating frames directory: \(error)")
        }
    }

    private func saveFrame(data: Data) {
        guard let directory = framesDirectory else { return }
        
        let fileName = String(format: "frame_%04d.png", frameCount)
        let fileURL = directory.appendingPathComponent(fileName)
        
        do {
            try data.write(to: fileURL)
            frameCount += 1
        } catch {
            print("Error saving frame: \(error)")
        }
    }
    
    func loadImagesFromDirectory(at path: URL) -> [UIImage] {
        do {
            let fileManager = FileManager.default
            let contents = try fileManager.contentsOfDirectory(at: path, includingPropertiesForKeys: nil, options: [])
            let imageFiles = contents.filter { $0.pathExtension == "png" }.sorted(by: { $0.lastPathComponent < $1.lastPathComponent })
            imageFiles.forEach { fileURL in
                print("Filename: \(fileURL.lastPathComponent)")
            }
            let images = imageFiles.compactMap { UIImage(contentsOfFile: $0.path) }
            return images
        } catch {
            print("Error reading contents of directory: \(error)")
            return []
        }
    }

    func generateVideoFromImages() {
        let images: [UIImage] = loadImagesFromDirectory(at: framesDirectory!)

        VideoGenerator.fileName = "outputVideo"
        VideoGenerator.videoDurationInSeconds = 1

        VideoGenerator.current.generate(withImages: images, andAudios: [], andType: .multiple, { (progress) in
          print(progress)
        }, outcome: { (url) in
          print(url)
        })
    }

}

#Preview {
    ContentView()
}
