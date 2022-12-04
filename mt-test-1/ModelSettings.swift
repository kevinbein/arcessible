//
//  ModelSettings.swift
//  mt-test-1
//
//  Created by Kevin Bein on 02.12.22.
//

import Foundation

/*
 //            .disableAutomaticLighting, // deprecated
 //            .disableGroundingShadows,
 //            .disableMotionBlur,
 //            //.disableDepthOfField, // we definitely need this
 //            .disableHDR,
 //            //.disableFaceOcclusions, // deprecated
 //            .disablePersonOcclusion,
 //            .disableAREnvironmentLighting,
 //            .disableFaceMesh
 */
struct ModelSettings {
    static func loadAndApplySettings(modelName: String) -> Bool {
        switch modelName {
            
        case "populating_exitSign":
            fallthrough
        case "populating_exitSignGround":
            MainARView.shared.debugOptions = []
            MainARView.shared.renderOptions = [
                //.disableAutomaticLighting, // deprecated
                //.disableGroundingShadows,
                //.disableMotionBlur,
                //.disableDepthOfField, // we definitely need this
                //.disableHDR,
                //.disableFaceOcclusions, // deprecated
                //.disablePersonOcclusion,
                //.disableAREnvironmentLighting,
                //.disableFaceMesh
            ]
            // WARNING: Line below does not work. Edit MainARView.swift around line 120 to enable or disable this for recordings.
            // I'm short on time and this can probably be solved by reloading the session or configuration or whatever and then
            // the value can be altered on run-time. Default is 1 ... btw.
            //MainARView.shared.environment.lighting.intensityExponent = 3 // Fucking thing, colors are now as expected
            MainARView.shared.resetSession()
            Log.print("Light intensity is now set to:", MainARView.shared.environment.lighting.intensityExponent)
            return true
            
        default:
            return false
        }
    }
}
