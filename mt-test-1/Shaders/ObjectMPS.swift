//
//  ObjectMPS.swift
//  mt-test-1
//
//  Created by Kevin Bein on 16.07.22.
//

import RealityKit

protocol ObjectMPS {
    func process(context: ARView.PostProcessContext) -> Void
}
