//
//  ReplaySceneSetup.swift
//  mt-test-1
//
//  Created by Kevin Bein on 27.11.22.
//

import Foundation
import RealityKit

class ReplaySceneSetup {
    
    enum ReplayScene {
        // CVD
        case cvdCipPool1, cvdCipPool2, cvdCipPool3
        case cvdFourthFloorAisle1, cvdFourthFloorAisle2, cvdFourthFloorAisle3
        case cvdFirstFloorTrashCans1, cvdFirstFloorTrashCans2, cvdFirstFloorTrashCans3
        case cvdChilloutBeforeLibrary1, cvdChilloutBeforeLibrary2, cvdChilloutBeforeLibrary3
        case cvdLibraryBetweenShelves1, cvdLibraryBetweenShelves2, cvdLibraryBetweenShelves3
        case cvdLibraryBetweenCubicles1, cvdLibraryBetweenCubicles2, cvdLibraryBetweenCubicles3
        
        // Motion
        case motionCipPool1, motionCipPool2, motionCipPool3
        case motionKitchen1, motionKitchen2, motionKitchen3
        case motionRoomHome1, motionRoomHome2, motionRoomHome3
        case motionExcellenceHall1, motionExcellenceHall2, motionExcellenceHall3
        case motionStatue1, motionStatue2, motionStatue3
        case motionSaloon1, motionSaloon2, motionSaloon3
    }
    
    struct SceneOptions {
        var hideUi: Bool = false
        var renderOptions: ARView.RenderOptions? = nil
        var debugOptions: ARView.DebugOptions? = nil
    }
    static let sceneOptions: [ReplayScene : SceneOptions] = [
        
        // CVD
        
        .cvdCipPool1: SceneOptions(hideUi: true, renderOptions: [], debugOptions: []),
        .cvdCipPool2: SceneOptions(hideUi: true, renderOptions: [], debugOptions: []),
        .cvdCipPool3: SceneOptions(hideUi: true, renderOptions: [], debugOptions: []),
        
        .cvdFourthFloorAisle1: SceneOptions(hideUi: true, renderOptions: [], debugOptions: []),
        .cvdFourthFloorAisle2: SceneOptions(hideUi: true, renderOptions: [], debugOptions: []),
        .cvdFourthFloorAisle3: SceneOptions(hideUi: true, renderOptions: [], debugOptions: []),
        
        .cvdFirstFloorTrashCans1: SceneOptions(hideUi: true, renderOptions: [], debugOptions: []),
        .cvdFirstFloorTrashCans2: SceneOptions(hideUi: true, renderOptions: [], debugOptions: []),
        .cvdFirstFloorTrashCans3: SceneOptions(hideUi: true, renderOptions: [], debugOptions: []),
        
        .cvdChilloutBeforeLibrary1: SceneOptions(hideUi: true, renderOptions: [], debugOptions: []),
        .cvdChilloutBeforeLibrary2: SceneOptions(hideUi: true, renderOptions: [], debugOptions: []),
        .cvdChilloutBeforeLibrary3: SceneOptions(hideUi: true, renderOptions: [], debugOptions: []),
        
        .cvdLibraryBetweenShelves1: SceneOptions(hideUi: true, renderOptions: [], debugOptions: []),
        .cvdLibraryBetweenShelves2: SceneOptions(hideUi: true, renderOptions: [], debugOptions: []),
        .cvdLibraryBetweenShelves3: SceneOptions(hideUi: true, renderOptions: [], debugOptions: []),
        
        .cvdLibraryBetweenCubicles1: SceneOptions(hideUi: true, renderOptions: [], debugOptions: []),
        .cvdLibraryBetweenCubicles2: SceneOptions(hideUi: true, renderOptions: [], debugOptions: []),
        .cvdLibraryBetweenCubicles3: SceneOptions(hideUi: true, renderOptions: [], debugOptions: []),
        
        // Motion
        
        .motionCipPool1: SceneOptions(hideUi: true, renderOptions: [], debugOptions: []),
        .motionCipPool2: SceneOptions(hideUi: true, renderOptions: [], debugOptions: []),
        .motionCipPool3: SceneOptions(hideUi: true, renderOptions: [], debugOptions: []),
    
        .motionKitchen1: SceneOptions(hideUi: true, renderOptions: [], debugOptions: []),
        .motionKitchen2: SceneOptions(hideUi: true, renderOptions: [], debugOptions: []),
        .motionKitchen3: SceneOptions(hideUi: true, renderOptions: [], debugOptions: []),
    
        .motionRoomHome1: SceneOptions(hideUi: true, renderOptions: [], debugOptions: []),
        .motionRoomHome2: SceneOptions(hideUi: true, renderOptions: [], debugOptions: []),
        .motionRoomHome3: SceneOptions(hideUi: true, renderOptions: [], debugOptions: []),
    
        .motionExcellenceHall1: SceneOptions(hideUi: true, renderOptions: [], debugOptions: []),
        .motionExcellenceHall2: SceneOptions(hideUi: true, renderOptions: [], debugOptions: []),
        .motionExcellenceHall3: SceneOptions(hideUi: true, renderOptions: [], debugOptions: []),
    
        .motionStatue1: SceneOptions(hideUi: true, renderOptions: [], debugOptions: []),
        .motionStatue2: SceneOptions(hideUi: true, renderOptions: [], debugOptions: []),
        .motionStatue3: SceneOptions(hideUi: true, renderOptions: [], debugOptions: []),
    
        .motionSaloon1: SceneOptions(hideUi: true, renderOptions: [], debugOptions: []),
        .motionSaloon2: SceneOptions(hideUi: true, renderOptions: [], debugOptions: []),
        .motionSaloon3: SceneOptions(hideUi: true, renderOptions: [], debugOptions: []),

    ]
    
    typealias SceneSetup = (modelName: String, position: SIMD3<Float>?, distanceToCamera: Float, distanceToPreviousObject: Float, transform: Transform?)
    static let sceneSetups: [ReplayScene : [String : SceneSetup]] = [

        // CVD
        
        .cvdCipPool1: [
            "80": ( "cvdDepthPerception.football", SIMD3<Float>(-0.06457245, -1.3716815, -1.4669635), 2.3160338, -1.0, Transform(
                scale: SIMD3<Float>(repeating: 1.0),
                rotation: Transform(pitch: 0, yaw: 0, roll: 0).rotation,
                translation: SIMD3<Float>(0.0, 0.0, 0.0)
            ) ),
        ],
        .cvdCipPool2: [
            "80": ( "cvdDepthPerception.football", SIMD3<Float>(-0.06457245, -1.3716815, -1.4669635), 2.3160338, -1.0, Transform(
                scale: SIMD3<Float>(repeating: 1.0),
                rotation: Transform(pitch: 0, yaw: 0, roll: 0).rotation,
                translation: SIMD3<Float>(0.0, 0.0, 0.0)
            ) ),
        ],
        .cvdCipPool3: [
            "80": ( "cvdDepthPerception.football", SIMD3<Float>(-0.06457245, -1.3716815, -1.4669635), 2.3160338, -1.0, Transform(
                scale: SIMD3<Float>(repeating: 1.0),
                rotation: Transform(pitch: 0, yaw: 0, roll: 0).rotation,
                translation: SIMD3<Float>(0.0, 0.0, 0.0)
            ) ),
        ],
        
        .cvdFourthFloorAisle1: [
            "488": ( "cvdDepthPerception.football", SIMD3<Float>(0.42777294, -1.2085482, 1.3601836), 2.1457708, -1.0, Transform(
                scale: SIMD3<Float>(repeating: 1.0),
                rotation: Transform(pitch: 0, yaw: 0, roll: 0).rotation,
                translation: SIMD3<Float>(0.0, 0.0, 0.0)
            ) ),
        ],
        .cvdFourthFloorAisle2: [
            "488": ( "cvdDepthPerception.football", SIMD3<Float>(0.42777294, -1.2085482, 1.3601836), 2.1457708, -1.0, Transform(
                scale: SIMD3<Float>(repeating: 1.0),
                rotation: Transform(pitch: 0, yaw: 0, roll: 0).rotation,
                translation: SIMD3<Float>(0.0, 0.0, 0.0)
            ) ),
        ],
        .cvdFourthFloorAisle3: [
            "488": ( "cvdDepthPerception.football", SIMD3<Float>(0.42777294, -1.2085482, 1.3601836), 2.1457708, -1.0, Transform(
                scale: SIMD3<Float>(repeating: 1.0),
                rotation: Transform(pitch: 0, yaw: 0, roll: 0).rotation,
                translation: SIMD3<Float>(0.0, 0.0, 0.0)
            ) ),
        ],
        
        .cvdFirstFloorTrashCans1: [
            "393": ( "cvdDepthPerception.football", SIMD3<Float>(-0.24023795, -1.3872586, 0.7269484), 2.859494, -1.0, Transform(
                scale: SIMD3<Float>(repeating: 1.0),
                rotation: Transform(pitch: 0, yaw: 0, roll: 0).rotation,
                translation: SIMD3<Float>(0.0, 0.0, 0.0)
            ) ),
        ],
        .cvdFirstFloorTrashCans2: [
            "393": ( "cvdDepthPerception.football", SIMD3<Float>(-0.24023795, -1.3872586, 0.7269484), 2.859494, -1.0, Transform(
                scale: SIMD3<Float>(repeating: 1.0),
                rotation: Transform(pitch: 0, yaw: 0, roll: 0).rotation,
                translation: SIMD3<Float>(0.0, 0.0, 0.0)
            ) ),
        ],
        .cvdFirstFloorTrashCans3: [
            "393": ( "cvdDepthPerception.football", SIMD3<Float>(-0.24023795, -1.3872586, 0.7269484), 2.859494, -1.0, Transform(
                scale: SIMD3<Float>(repeating: 1.0),
                rotation: Transform(pitch: 0, yaw: 0, roll: 0).rotation,
                translation: SIMD3<Float>(0.0, 0.0, 0.0)
            ) ),
        ],
        
        .cvdChilloutBeforeLibrary1: [
            "353": ( "cvdDepthPerception.football", SIMD3<Float>(-0.08777763, -1.2897413, -0.9061769), 2.5622227, -1.0, Transform(
                scale: SIMD3<Float>(repeating: 1.0),
                rotation: Transform(pitch: 0, yaw: 0, roll: 0).rotation,
                translation: SIMD3<Float>(0.0, 0.0, 0.0)
            ) ),
        ],
        .cvdChilloutBeforeLibrary2: [
            "353": ( "cvdDepthPerception.football", SIMD3<Float>(-0.08777763, -1.2897413, -0.9061769), 2.5622227, -1.0, Transform(
                scale: SIMD3<Float>(repeating: 1.0),
                rotation: Transform(pitch: 0, yaw: 0, roll: 0).rotation,
                translation: SIMD3<Float>(0.0, 0.0, 0.0)
            ) ),
        ],
        .cvdChilloutBeforeLibrary3: [
            "353": ( "cvdDepthPerception.football", SIMD3<Float>(-0.08777763, -1.2897413, -0.9061769), 2.5622227, -1.0, Transform(
                scale: SIMD3<Float>(repeating: 1.0),
                rotation: Transform(pitch: 0, yaw: 0, roll: 0).rotation,
                translation: SIMD3<Float>(0.0, 0.0, 0.0)
            ) ),
        ],
        
        .cvdLibraryBetweenShelves1: [
            "370": ( "cvdDepthPerception.football", SIMD3<Float>(0.07647643, -1.3772019, -2.4223554), 5.5403886, -1.0, Transform(
                scale: SIMD3<Float>(repeating: 1.0),
                rotation: Transform(pitch: 0, yaw: 0, roll: 0).rotation,
                translation: SIMD3<Float>(0.0, 0.0, 0.2)
            ) ),
        ],
        .cvdLibraryBetweenShelves2: [
            "370": ( "cvdDepthPerception.football", SIMD3<Float>(0.07647643, -1.3772019, -2.4223554), 5.5403886, -1.0, Transform(
                scale: SIMD3<Float>(repeating: 1.0),
                rotation: Transform(pitch: 0, yaw: 0, roll: 0).rotation,
                translation: SIMD3<Float>(0.0, 0.0, 0.0)
            ) ),
        ],
        .cvdLibraryBetweenShelves3: [
            "370": ( "cvdDepthPerception.football", SIMD3<Float>(0.07647643, -1.3772019, -2.4223554), 5.5403886, -1.0, Transform(
                scale: SIMD3<Float>(repeating: 1.0),
                rotation: Transform(pitch: 0, yaw: 0, roll: 0).rotation,
                translation: SIMD3<Float>(0.0, 0.0, 0.0)
            ) ),
        ],
        
        .cvdLibraryBetweenCubicles1: [
            "249": ( "cvdDepthPerception.football", SIMD3<Float>(-0.088997886, -1.3950207, -2.9579158), 3.6538632, -1.0, Transform(
                scale: SIMD3<Float>(repeating: 1.0),
                rotation: Transform(pitch: 0, yaw: 0, roll: 0).rotation,
                translation: SIMD3<Float>(0.15, 0.0, 0.0)
            ) ),
        ],
        .cvdLibraryBetweenCubicles2: [
            "249": ( "cvdDepthPerception.football", SIMD3<Float>(-0.088997886, -1.3950207, -2.9579158), 3.6538632, -1.0, Transform(
                scale: SIMD3<Float>(repeating: 1.0),
                rotation: Transform(pitch: 0, yaw: 0, roll: 0).rotation,
                translation: SIMD3<Float>(0.15, 0.0, 0.0)
            ) ),
        ],
        .cvdLibraryBetweenCubicles3: [
            "249": ( "cvdDepthPerception.football", SIMD3<Float>(-0.088997886, -1.3950207, -2.9579158), 3.6538632, -1.0, Transform(
                scale: SIMD3<Float>(repeating: 1.0),
                rotation: Transform(pitch: 0, yaw: 0, roll: 0).rotation,
                translation: SIMD3<Float>(0.15, 0.0, 0.0)
            ) ),
        ],
        
        // Motion
        .motionCipPool1: [
            "182": ( "cvdDepthPerception.boxinggloves", SIMD3<Float>(0.1741442, -1.2875509, -2.4676213), 3.079836, -1.0, Transform(
                scale: SIMD3<Float>(repeating: 1.0),
                rotation: Transform(pitch: 0, yaw: 0, roll: 0).rotation,
                translation: SIMD3<Float>(0.0, 0.0, -0.5)
            ) ),
        ],
        .motionCipPool2: [
            "182": ( "cvdDepthPerception.boxinggloves", SIMD3<Float>(0.1741442, -1.2875509, -2.4676213), 3.079836, -1.0, Transform(
                scale: SIMD3<Float>(repeating: 1.0),
                rotation: Transform(pitch: 0, yaw: 0, roll: 0).rotation,
                translation: SIMD3<Float>(0.0, 0.0, 1.5)
            ) ),
        ],
        .motionCipPool3: [
            "182": ( "cvdDepthPerception.boxinggloves", SIMD3<Float>(0.1741442, -1.2875509, -2.4676213), 3.079836, -1.0, Transform(
                scale: SIMD3<Float>(repeating: 1.0),
                rotation: Transform(pitch: 0, yaw: 0, roll: 0).rotation,
                translation: SIMD3<Float>(0.0, 0.0, 3.5)
            ) ),
        ],
        
        .motionExcellenceHall1: [
            "131": ( "cvdDepthPerception.boxinggloves", SIMD3<Float>(-0.0749607, -1.4451501, -2.6127236), 2.9773934, -1.0, Transform(
                scale: SIMD3<Float>(repeating: 1.0),
                rotation: Transform(pitch: 0, yaw: 0, roll: 0).rotation,
                translation: SIMD3<Float>(0.0, 0.0, 0)
            ) ),
        ],
        .motionExcellenceHall2: [
            "131": ( "cvdDepthPerception.boxinggloves", SIMD3<Float>(-0.0749607, -1.4451501, -2.6127236), 2.9773934, -1.0, Transform(
                scale: SIMD3<Float>(repeating: 1.0),
                rotation: Transform(pitch: 0, yaw: 0, roll: 0).rotation,
                translation: SIMD3<Float>(0.0, 0.0, 3.0)
            ) ),
        ],
        .motionExcellenceHall3: [
            "131": ( "cvdDepthPerception.boxinggloves", SIMD3<Float>(-0.0749607, -1.4451501, -2.6127236), 2.9773934, -1.0, Transform(
                scale: SIMD3<Float>(repeating: 1.0),
                rotation: Transform(pitch: 0, yaw: 0, roll: 0).rotation,
                translation: SIMD3<Float>(0.0, 0.0, 8.0)
            ) ),
        ],
        
        .motionStatue1: [
            "104": ( "cvdDepthPerception.boxinggloves", SIMD3<Float>(0.013870473, -1.2409208, -2.2676356), 2.6140704, -1.0, Transform(
                scale: SIMD3<Float>(repeating: 1.0),
                rotation: Transform(pitch: 0, yaw: 0, roll: 0).rotation,
                translation: SIMD3<Float>(0.0, 0.0, 0.5)
            ) ),
        ],
        .motionStatue2: [
            "104": ( "cvdDepthPerception.boxinggloves", SIMD3<Float>(0.013870473, -1.2409208, -2.2676356), 2.6140704, -1.0, Transform(
                scale: SIMD3<Float>(repeating: 1.0),
                rotation: Transform(pitch: 0, yaw: 0, roll: 0).rotation,
                translation: SIMD3<Float>(-1.0, 0.0, 3.5)
            ) ),
        ],
        .motionStatue3: [
            "104": ( "cvdDepthPerception.boxinggloves", SIMD3<Float>(0.013870473, -1.2409208, -2.2676356), 2.6140704, -1.0, Transform(
                scale: SIMD3<Float>(repeating: 1.0),
                rotation: Transform(pitch: 0, yaw: 0, roll: 0).rotation,
                translation: SIMD3<Float>(-1.0, 0.0, 6.5)
            ) ),
        ],
        
        .motionSaloon1: [
            "147": ( "cvdDepthPerception.boxinggloves", SIMD3<Float>(0.04189506, -1.3267632, -1.7888794), 2.4001415, -1.0, Transform(
                scale: SIMD3<Float>(repeating: 1.0),
                rotation: Transform(pitch: 0, yaw: 0, roll: 0).rotation,
                translation: SIMD3<Float>(0.0, 0.0, 0.0)
            ) ),
        ],
        .motionSaloon2: [
            "147": ( "cvdDepthPerception.boxinggloves", SIMD3<Float>(0.04189506, -1.3267632, -1.7888794), 2.4001415, -1.0, Transform(
                scale: SIMD3<Float>(repeating: 1.0),
                rotation: Transform(pitch: 0, yaw: 0, roll: 0).rotation,
                translation: SIMD3<Float>(0.0, 0.0, 3.0)
            ) ),
        ],
        .motionSaloon3: [
            "147": ( "cvdDepthPerception.boxinggloves", SIMD3<Float>(0.04189506, -1.3267632, -1.7888794), 2.4001415, -1.0, Transform(
                scale: SIMD3<Float>(repeating: 1.0),
                rotation: Transform(pitch: 0, yaw: 0, roll: 0).rotation,
                translation: SIMD3<Float>(0.0, 0.0, 6.0)
            ) ),
        ],
        
        .motionKitchen1: [
            "182": ( "cvdDepthPerception.boxinggloves", SIMD3<Float>(0.031089803, -0.5275846, -0.63921916), 0.9597021, -1.0, Transform(
                scale: SIMD3<Float>(repeating: 1.0),
                rotation: Transform(pitch: 0, yaw: 0, roll: 0).rotation,
                translation: SIMD3<Float>(0.0, 0.0, 0.2)
            ) ),
        ],
        .motionKitchen2: [
            "182": ( "cvdDepthPerception.boxinggloves", SIMD3<Float>(0.031089803, -0.5275846, -0.63921916), 0.9597021, -1.0, Transform(
                scale: SIMD3<Float>(repeating: 1.0),
                rotation: Transform(pitch: 0, yaw: 0, roll: 0).rotation,
                translation: SIMD3<Float>(0.0, 0.0, 2.2)
            ) ),
        ],
        .motionKitchen3: [
            "182": ( "cvdDepthPerception.boxinggloves", SIMD3<Float>(0.031089803, -0.5275846, -0.63921916), 0.9597021, -1.0, Transform(
                scale: SIMD3<Float>(repeating: 1.0),
                rotation: Transform(pitch: 0, yaw: 0, roll: 0).rotation,
                translation: SIMD3<Float>(0.0, 0.0, 3.2)
            ) ),
        ],
        
        .motionRoomHome1: [
            "54": ( "cvdDepthPerception.boxinggloves", SIMD3<Float>(-0.011786578, -1.1612731, -0.681921), 1.4775909, -1.0, Transform(
                scale: SIMD3<Float>(repeating: 1.0),
                rotation: Transform(pitch: 0, yaw: 0, roll: 0).rotation,
                translation: SIMD3<Float>(0.0, 0.0, 0.2)
            ) ),
        ],
        .motionRoomHome2: [
            "54": ( "cvdDepthPerception.boxinggloves", SIMD3<Float>(-0.011786578, -1.1612731, -0.681921), 1.4775909, -1.0, Transform(
                scale: SIMD3<Float>(repeating: 1.0),
                rotation: Transform(pitch: 0, yaw: 0, roll: 0).rotation,
                translation: SIMD3<Float>(0.0, 0.0, 1.2)
            ) ),
        ],
        .motionRoomHome3: [
            "54": ( "cvdDepthPerception.boxinggloves", SIMD3<Float>(-0.011786578, -1.1612731, -0.681921), 1.4775909, -1.0, Transform(
                scale: SIMD3<Float>(repeating: 1.0),
                rotation: Transform(pitch: 0, yaw: 0, roll: 0).rotation,
                translation: SIMD3<Float>(0.0, 0.0, 2.2)
            ) ),
        ],
    ]
    
    private static func loadShaders(replayScene: ReplayScene, view: MainARView) {
        var shaders: [MainARView.ShaderDescriptor] = []
        
        switch replayScene {
       
        // Trichromat
        case .cvdFourthFloorAisle1: fallthrough
        case .cvdFirstFloorTrashCans1: fallthrough
        case .cvdChilloutBeforeLibrary1: fallthrough
        case .cvdLibraryBetweenShelves1: fallthrough
        case .cvdLibraryBetweenCubicles1: fallthrough
        case .cvdCipPool1:
            let hsbcContrast: Float = 1.0
            shaders.append(MainARView.ShaderDescriptor(shader: MainARView.Shader(name: "hsbc", type: .metalShader, mpsObject: LaplacianMPS()), arguments: [ 0.0, 0.5, 0.5, 1.0, 0.0 ], textures: []))
            view.runShaders(chain: MainARView.ShaderChain(shaders: shaders, pipelineTarget: .correction, frameMode: .combined))
        
        // Dichromat
        case .cvdFourthFloorAisle2: fallthrough
        case .cvdFirstFloorTrashCans2: fallthrough
        case .cvdChilloutBeforeLibrary2: fallthrough
        case .cvdLibraryBetweenShelves2: fallthrough
        case .cvdLibraryBetweenCubicles2: fallthrough
        case .cvdCipPool2:
            let hsbcContrast: Float = 1.0
            shaders.append(MainARView.ShaderDescriptor(shader: MainARView.Shader(name: "hsbc", type: .metalShader, mpsObject: LaplacianMPS()), arguments: [ 0.0, 0.5, 0.5, 1.0, 0.0 ], textures: []))
            let cvdType: Float = 1.0
            let cvdSeverity: Float = 1.0
            let cvdArgs: [Float] = [ cvdType, cvdSeverity ]
            shaders.append(MainARView.ShaderDescriptor(shader: MainARView.Shader(name: "colorVisionDeficiency", type: .metalShader), arguments: cvdArgs, textures: []))
            view.runShaders(chain: MainARView.ShaderChain(shaders: shaders, pipelineTarget: .correction, frameMode: .combined))
          
        case .cvdFourthFloorAisle3: fallthrough
        case .cvdFirstFloorTrashCans3: fallthrough
        case .cvdChilloutBeforeLibrary3: fallthrough
        case .cvdLibraryBetweenShelves3: fallthrough
        case .cvdLibraryBetweenCubicles3: fallthrough
        case .cvdCipPool3:
            let hsbcContrast: Float = 1.0
            shaders.append(MainARView.ShaderDescriptor(shader: MainARView.Shader(name: "hsbc", type: .metalShader, mpsObject: LaplacianMPS()), arguments: [ 0.0, 0.5, 0.5, 0.0, 0.0 ], textures: []))
            view.runShaders(chain: MainARView.ShaderChain(shaders: shaders, pipelineTarget: .correction, frameMode: .combined))
             
            
        // edge enhancement
        /*case .cipPool3:
            // Detect edges
            shaders.append(MainARView.ShaderDescriptor(shader: MainARView.Shader(name: "sobel", type: .metalPerformanceShader, mpsObject: SobelMPS()), arguments: [], textures: []))
            // grey scale
            shaders.append(MainARView.ShaderDescriptor(shader: MainARView.Shader(name: "hsbc", type: .metalShader, mpsObject: LaplacianMPS()), arguments: [ 0.0, 0.5, 0.5, 0.0, 0.0 ], textures: [], targetTexture: "detectedEdges"))
            // mix
            shaders.append(MainARView.ShaderDescriptor(shader: MainARView.Shader(name: "edgeEnhancement", type: .metalShader), arguments: [ 5.0 ], textures: ["detectedEdges", "g_startCombinedBackgroundAndModelTexture"]))
            // view.runShaders(chain: MainARView.ShaderChain(shaders: shaders, pipelineTarget: .correction))
            let hsbcContrast: Float = 1.0
            shaders.append(MainARView.ShaderDescriptor(shader: MainARView.Shader(name: "hsbc", type: .metalShader, mpsObject: LaplacianMPS()), arguments: [ 0.0, 0.5, 0.5, 1.0, 0.0 ], textures: []))
            let cvdType: Float = 1.0
            let cvdSeverity: Float = 1.0
            let cvdArgs: [Float] = [ cvdType, cvdSeverity ]
            shaders.append(MainARView.ShaderDescriptor(shader: MainARView.Shader(name: "colorVisionDeficiency", type: .metalShader), arguments: cvdArgs, textures: []))
            view.runShaders(chain: MainARView.ShaderChain(shaders: shaders, pipelineTarget: .correction))
        */
        
        default:
            return
            
        }
    }
    
    static func setupReplay(forRecording: ReplayScene?) {
        guard let replayName = forRecording else { return }
        guard let options = sceneOptions[replayName] else { return }
        
        loadedShaders = false
        
        if options.renderOptions != nil {
            MainARView.shared.renderOptions = options.renderOptions!
        }
        
        if (options.debugOptions != nil) {
            MainARView.shared.debugOptions = options.debugOptions!
        }
        
        Log.print("ReplaySceneSetup: Set up replay scene")
    }
    
    static var loadedShaders = false
    static func renderSceneNext(forRecording: ReplayScene?, frameNumber: Int, view: MainARView) {
        guard let replayName = forRecording else { return }
        guard let data = sceneSetups[replayName] else { return }
        
        if !loadedShaders {
            // let configuration = view.session.configuration
            loadShaders(replayScene: replayName, view: view)
            loadedShaders = true
            Log.print("ReplaySceneSetup: Loaded shaders at frameNumber = 0")
        }
        
        guard let entry = data[String(frameNumber)] else { return }
        
        let fullName = entry.modelName
        let nameComponents = fullName.components(separatedBy: ".")
        let modelName = nameComponents[0]
        let sceneName = nameComponents[1]
        
        var varPosition: SIMD3<Float>
        if (entry.position == nil) {
            if MainARViewContainer.focusEntity != nil {
                varPosition = MainARViewContainer.focusEntity!.position
            } else {
                Log.print("ReplaySceneSetup: No position available (focusEntity)")
                return
            }
        } else {
            varPosition = entry.position!
        }
        
        let position = varPosition
        
        var anchor = AnchorEntity(plane: .horizontal)
        anchor.position = position
        guard let model = AccessibleModel.load(named: modelName, scene: sceneName) else {
            fatalError("ReplaySceneSetup: Failed loading model '\(modelName)'")
        }
        
        if entry.transform != nil {
            Log.print("ReplaySceneSetup: Applied transform from", model.children.first!.transform, "to", entry.transform)
            model.children.first!.transform = entry.transform!
        }
        
        anchor.addChild(model)
        view.scene.addAnchor(anchor)
        
        Log.print("ReplaySceneSetup: (\(frameNumber)) Added model \(modelName) at \(position)")
    }
    
}
