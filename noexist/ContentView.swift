//

import SwiftUI
import SceneKit

import SwiftUI
import SceneKit
import AVFoundation

struct ContentView: View {
    let usdzFile = "Balenciaga_Defender"
    @State private var captureSnapshot = false
    @State private var record = false

    var body: some View {
        VStack {
            SceneKitView(fileName: usdzFile, captureSnapshot: $captureSnapshot)
                .frame(height: 300)
                .padding()
                .cornerRadius(12)

            Button("Capture Snapshot") {
                captureSnapshot = true
            }
            .padding()
            .background(.black)
            .foregroundColor(.white)
            Button("Record") {
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
            let rotation = SCNAction.rotateBy(x: 0, y: 0, z: CGFloat.pi * 2, duration: 10) // rotate to z
            let repeatRotation = SCNAction.repeatForever(rotation)
            rootNode.runAction(repeatRotation)

            sceneView.scene = scene
        }
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

#Preview {
    ContentView()
}

