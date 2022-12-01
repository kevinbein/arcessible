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
            Color.indigo.edgesIgnoringSafeArea(.all)
#if targetEnvironment(simulator)
            Color.gray.edgesIgnoringSafeArea(.all)
#else
            //MainBGContainer(arFrame: frameModel.frame)
            //    .edgesIgnoringSafeArea(.all)
            
            MainARViewContainer(frame: $frameModel.frame)
                .edgesIgnoringSafeArea(.all)
            
//            MainFGContainer()
//                .edgesIgnoringSafeArea(.all)
#endif
            MainUIView()
                .edgesIgnoringSafeArea(.all)
        
        }
    }
}

#if DEBUG
struct ContentView_Previews : PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
#endif
