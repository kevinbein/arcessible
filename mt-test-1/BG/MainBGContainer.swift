//
//  MainBGView.swift
//  mt-test-1
//
//  Created by Kevin Bein on 05.05.22.
//

import SwiftUI

struct MainBGContainer: View {
    var frame: CGImage?
    
    var body: some View {
        if let image = frame {
            GeometryReader { geometry in
                Image(image, scale: 1.0, orientation: .right, label: Text("Video feed"))
                    .resizable()
                    .scaledToFill()
                    .frame(
                        width: geometry.size.width,
                        height: geometry.size.height,
                        alignment: .center)
                    .clipped()
            }
        } else {
            EmptyView()
        }
    }
}

struct MainBGContainer_Previews: PreviewProvider {
    static var previews: some View {
        MainBGContainer(frame: nil)
    }
}
