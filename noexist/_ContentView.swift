//

import SwiftUI
import SceneKit

import SwiftUI
import SceneKit
import AVFoundation

struct _ContentView: View {
    let usdzFile = "Balenciaga_Defender"
    @State private var isRecording = false

    var body: some View {
        _SceneKitView(fileName: usdzFile, isRecording: $isRecording)
            .frame(height: 300)
            .padding()
            .cornerRadius(12)
        Button(action: {
                    self.isRecording.toggle()
                }) {
                    Text(isRecording ? "Stop Recording" : "Start Recording")
                        .foregroundColor(isRecording ? .red : .white)
                        .padding()
                        .background(.black)
                }
                .padding()
    }
}

struct _SceneKitView: UIViewRepresentable {
    let fileName: String
    @Binding var isRecording: Bool
    @State private var sceneRecorder = _SceneRecorder()

    func makeUIView(context: Context) -> SCNView {
        let sceneView = SCNView()
        sceneView.autoenablesDefaultLighting = true
        sceneView.allowsCameraControl = true

        if let url = Bundle.main.url(forResource: fileName, withExtension: "usdz"),
           let scene = try? SCNScene(url: url, options: nil) {
            let rootNode = scene.rootNode

            rootNode.eulerAngles = SCNVector3(0, 0, 0)
            rootNode.position = SCNVector3(0, 0, 0)
            rootNode.scale = SCNVector3(1, 1, 1)
            let rotation = SCNAction.rotateBy(x: 0, y: 0, z: CGFloat.pi * 2, duration: 10) // rotate to z
            let repeatRotation = SCNAction.repeatForever(rotation)
            rootNode.runAction(repeatRotation)

            sceneView.scene = scene
        }

        return sceneView
    }
    
    func updateUIView(_ uiView: SCNView, context: Context) {
        if isRecording {
            sceneRecorder.startRecording(from: uiView.scene!, size: uiView.bounds.size)
        } else {
            sceneRecorder.stopRecording()
        }
    }

}

class _SceneRecorder {
    var sceneRenderer: _SceneRenderer?
    var isRecording: Bool = false
    // Other necessary properties for video writing

    func startRecording(from scene: SCNScene, size: CGSize) {
        // Initialize SceneRenderer
        print("start")
        self.sceneRenderer = _SceneRenderer(scene: scene, size: size)

        // Setup video output and start recording
        self.isRecording = true
    }

    func stopRecording() {
        // Stop recording and finalize video
        self.isRecording = false
    }
}

class _SceneRenderer {
    private var scnRenderer: SCNRenderer
    private var scene: SCNScene
    private var size: CGSize

    init(scene: SCNScene, size: CGSize) {
        self.scene = scene
        self.size = size
        self.scnRenderer = SCNRenderer(device: nil, options: nil)
        self.scnRenderer.scene = scene
        self.scnRenderer.autoenablesDefaultLighting = true
    }

    func captureFrame(atTime time: CFTimeInterval) -> UIImage? {
        if let cameraNode = scene.rootNode.childNode(withName: "cameraName", recursively: true) {
            self.scnRenderer.pointOfView = cameraNode
        }
        let image = self.scnRenderer.snapshot(atTime: time, with: size, antialiasingMode: .none)
        return image
    }
}

#Preview {
    _ContentView()
}

