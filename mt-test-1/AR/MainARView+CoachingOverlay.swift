//
//  MainARView+CoachingOverlayDelegate.swift
//  mt-test-1
//
//  Created by Kevin Bein on 01.05.22.
//

import ARKit
import UIKit

extension MainARView: ARCoachingOverlayViewDelegate {
    func setupCoachingOverlay() {
        let coachingOverlay = ARCoachingOverlayView()
        coachingOverlay.delegate = self
        coachingOverlay.session = self.session
        coachingOverlay.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        coachingOverlay.goal = .horizontalPlane
        coachingOverlay.activatesAutomatically = false
        self.addSubview(coachingOverlay)
    }
}
