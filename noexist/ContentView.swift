//

import SwiftUI
import SceneKit
import AVFoundation

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
            Button("play") {
                sceneHolder.addRotationAnimation(x: 0, y: 0, z: CGFloat.pi * 2/4, duration: 2)
                sceneHolder.applyAnimations()
            }
            .padding()
            .background(.black)
            .foregroundColor(.white)
            Button("move") {
                sceneHolder.addRotationAnimation(x: 0, y: 0, z: CGFloat.pi * 2, duration: 10)
                sceneHolder.updateAnimation(5.0)
            }
            .padding()
            .background(.black)
            .foregroundColor(.white)
            Button("export") {
                sceneHolder.addRotationAnimation(x: 0, y: 0, z: CGFloat.pi * 2/4, duration: 2)
                sceneHolder.exportVideo()
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
            sceneView.scene = scene
            sceneHolder.scnView = sceneView
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
    
    static func rotate(for scnScene: SCNScene, x: CGFloat, y: CGFloat, z: CGFloat, duration: TimeInterval) {
        let rootNode = scnScene.rootNode
        rootNode.eulerAngles = SCNVector3(0, 0, 0)
        rootNode.position = SCNVector3(0, 0, 0)
        rootNode.scale = SCNVector3(1, 1, 1)
        let rotation = SCNAction.rotateBy(x: x, y: y, z: z, duration: duration)
        let repeatRotation = SCNAction.repeatForever(rotation)
        rootNode.runAction(repeatRotation, forKey: "rotationKey")
    }
}

class SceneHolder: ObservableObject {
    @Published var scnView: SCNView?
    var animation: Animation?
    @State private var frameCaptureManager: FrameCaptureManager?

    init() {}
    
    func addRotationAnimation(x: CGFloat, y: CGFloat, z: CGFloat, duration: TimeInterval) {
        let keyframes = [
            Keyframe(time: 0, rotation: SCNVector4(0, 0, 0, 0)),
            Keyframe(time: duration, rotation: SCNVector4(x, y, z, CGFloat.pi * 2))
        ]

        animation = Animation(keyframes: keyframes, duration: duration)
    }
    
    func applyAnimations() {
        guard let scnView = scnView, let rootNode = scnView.scene?.rootNode else { return }
        let animator = Animator(node: rootNode)
        animator.animation = self.animation
        animator.applyAnimation()
    }
    
    func updateAnimation(_ to: TimeInterval) {
        guard let scnView = scnView, let rootNode = scnView.scene?.rootNode else { return }
        let animator = Animator(node: rootNode)
        animator.animation = self.animation
        animator.updateAnimation(to: to)
    }
    
    func exportVideo() {
        guard let scnView = scnView, let scene = scnView.scene else { return }
        let animator = Animator(node: scene.rootNode)
        animator.animation = self.animation
        let frameCaptureManager = FrameCaptureManager(scene: scene, view: scnView, animator: animator)
        frameCaptureManager.startCapture()
    }
}

struct Keyframe {
    var time: TimeInterval
    var rotation: SCNVector4
}

struct Animation {
    var keyframes: [Keyframe]
    var duration: TimeInterval
}

class Animator {
    var animation: Animation?
    weak var node: SCNNode?

    init(node: SCNNode) {
        self.node = node
    }

    func applyAnimation() {
        guard let animation = animation, let node = node else { return }
        
        let actions = animation.keyframes.map { keyframe -> SCNAction in
            SCNAction.rotateTo(x: CGFloat(keyframe.rotation.x),
                               y: CGFloat(keyframe.rotation.y),
                               z: CGFloat(keyframe.rotation.z),
                               duration: keyframe.time)
        }
        
        let sequence = SCNAction.sequence(actions)
        node.runAction(sequence, forKey: "rotationAnimation")
    }
    
    func updateAnimation(to time: TimeInterval) {
        guard let animation = animation, let node = node else { return }

        // Calculate the state of the animation at the given time
        // This is a simplified example and assumes linear interpolation
        if let firstKeyframe = animation.keyframes.first,
           let lastKeyframe = animation.keyframes.last {
            
            let progress = min(max(time / animation.duration, 0), 1)
            let startRotation = firstKeyframe.rotation
            let endRotation = lastKeyframe.rotation
            let interpolatedRotation = interpolate(start: startRotation, end: endRotation, progress: progress)
            
            node.eulerAngles = SCNVector3(interpolatedRotation.x, interpolatedRotation.y, interpolatedRotation.z)
        }
    }

    private func interpolate(start: SCNVector4, end: SCNVector4, progress: CGFloat) -> SCNVector4 {
        let floatProgress = Float(progress)  // Convert progress to Float

        let deltaX = (end.x - start.x) * floatProgress
        let deltaY = (end.y - start.y) * floatProgress
        let deltaZ = (end.z - start.z) * floatProgress
        let deltaW = (end.w - start.w) * floatProgress

        let interpolatedX = start.x + deltaX
        let interpolatedY = start.y + deltaY
        let interpolatedZ = start.z + deltaZ
        let interpolatedW = start.w + deltaW

        return SCNVector4(interpolatedX, interpolatedY, interpolatedZ, interpolatedW)
    }

    func play() {
        // Ensure the node is at the starting position
        node?.eulerAngles = SCNVector3(0, 0, 0)
        
        // Apply the animation
        applyAnimation()
    }
}

#Preview {
    ContentView()
}
