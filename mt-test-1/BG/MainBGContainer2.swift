//
//  MainBGView.swift
//  mt-test-1
//
//  Created by Kevin Bein on 05.05.22.
//

import SwiftUI

struct MainBGContainer2: View {
    @Binding var frame: CGImage?
    
    var body: some View {
        //Rectangle().foregroundColor(.red).frame(width: 20, height: 20, alignment: .top)
        Spacer()
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
