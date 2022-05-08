//
//  ContentView.swift
//  mt-test-1
//
//  Created by Kevin Bein on 08.04.22.
//

import ARKit
import SwiftUI
import RealityKit

struct ContentView : View {
    @StateObject private var frameModel = FrameModel()
    
    var body: some View {
        ZStack {
            Color.red.edgesIgnoringSafeArea(.all)
#if targetEnvironment(simulator)
            Color.gray.edgesIgnoringSafeArea(.all)
#else
            MainBGContainer(arFrame: frameModel.frame)
                .edgesIgnoringSafeArea(.all)
            
            MainARViewContainer(frame: $frameModel.frame)
                .edgesIgnoringSafeArea(.all)
#endif
            MainUIView()
        }
    }
    
    /*var body: some View {
        VStack {
            // LogoUIView()
            
            // GreetingsUIView()
            
            Button("Next") {
                /*@START_MENU_TOKEN@*//*@PLACEHOLDER=Action@*/ /*@END_MENU_TOKEN@*/
            }.padding()
            
            Spacer()
        }.padding()
        //return ARViewContainer().edgesIgnoringSafeArea(.all)
    }*/
}

/*struct ARViewContainer: UIViewRepresentable {
    
    func makeUIView(context: Context) -> ARView {
        
        let arView = ARView(frame: .zero)
        
        // Start AR session
        let session = arView.session
        let config = ARWorldTrackingConfiguration()
        config.planeDetection = [.horizontal]
        session.run(config)
        
        // Add coaching overlay
        let coachingOverlay = ARCoachingOverlayView()
        coachingOverlay.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        coachingOverlay.session = session
        coachingOverlay.goal = .horizontalPlane
        arView.addSubview(coachingOverlay)
        
        // Set debug options
        #if DEBUG
        arView.debugOptions = [.showFeaturePoints, .showAnchorOrigins, .showAnchorGeometry, .showSceneUnderstanding]
        #endif
        
        // Load the "Box" scene from the "Experience" Reality File
        // let boxAnchor = try! Experience.loadBox()
        
        // Add the box anchor to the scene
        // arView.scene.anchors.append(boxAnchor)
        
        return arView
        
    }
    
    func updateUIView(_ uiView: ARView, context: Context) {}
    
}*/

#if DEBUG
struct ContentView_Previews : PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
#endif
