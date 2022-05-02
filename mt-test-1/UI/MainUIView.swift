//
//  MainUIView.swift
//  mt-test-1
//
//  Created by Kevin Bein on 28.04.22.
//

import SwiftUI

struct PrimaryButton: UIViewRepresentable {
    let title: String
    let action: () -> ()
    
    func makeCoordinator() -> Coordinator { Coordinator(self) }

    class Coordinator: NSObject {
        var parent: PrimaryButton

        init(_ pillButton: PrimaryButton) {
            self.parent = pillButton
            super.init()
        }

        @objc func doAction(_ sender: Any) {
            self.parent.action()
        }
    }
    
    func makeUIView(context: Context) -> UIButton {
        let button = UIButton(configuration: .filled(), primaryAction: nil)
        button.setTitle(self.title, for: .normal)
        button.addTarget(context.coordinator, action: #selector(Coordinator.doAction(_ :)), for: .touchDown)
        return button
    }

    func updateUIView(_ uiView: UIButton, context: Context) {}
}

struct MainUIView: View {
    @State private var showAbout = false
    
    @State private var posX = 0.5
    @State private var posY = 0.5
    @State private var posZ = 0.5
    
    func onButton1() {}
    func onButton2() {}
    func onButton3() {}
    
    var body: some View {
        let content = VStack {
            Text("Blah ...")
            Text("... Blub")
        }.foregroundColor(.white)
        
        let blackOpacity = 0.2
        let safeAreaHeightTop = UIApplication.shared.keyWindow?.safeAreaInsets.top
        let safeAreaHeightBottom = UIApplication.shared.keyWindow?.safeAreaInsets.bottom
        
        Group {
            VStack(spacing: 0) {
                // Header - Top margin
                Rectangle()
                    .foregroundColor(.black.opacity(0))
                    .frame(height: safeAreaHeightTop)
                
                // Header - Title
                HStack {
                    Text(ProjectSettings.appName)
                        .font(.largeTitle)
                        .bold()
                        .foregroundColor(.white)
                    Spacer()
                    Button(action: {
                        showAbout = true
                    }) {
                        Label("", systemImage: "info.circle")
                            .font(.title)
                            .foregroundColor(.blue)
                    }
                    .alert(isPresented: $showAbout) {
                        Alert(
                           title: Text("About"),
                           message: Text("\n\(ProjectSettings.authorName)\n\(ProjectSettings.authorEmail)")
                       )
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.all)
                .background(.black.opacity(blackOpacity))
                
                Spacer()
                
                // Content
                Group {
                    content
                        .padding()
                }
                .background(.black.opacity(blackOpacity))
                
                Spacer()
                
                // Footer - Top margin
                Group {
                    Rectangle()
                        .foregroundColor(.black.opacity(blackOpacity))
                        .frame(height: 10)
                    
                    // Footer - Controls
                    VStack {
                        // Footer - Controls - Buttons
                        HStack {
                            PrimaryButton(title: "Button 1", action: onButton1)
                            PrimaryButton(title: "Button 2", action: onButton2)
                            PrimaryButton(title: "Button 3", action: onButton3)
                        }
                        .aspectRatio(contentMode: .fit)
                        // Footer - Controls - Sliders
                        HStack {
                            Spacer()
                            VStack {
                                Slider(value: $posX, in: 0.0...1.0, step: 0.05).onChange(of: posX) { posX in
                                    print(posX)
                                }
                                Text("\(String(format: "X: %.2f", posX))")
                            }
                            VStack {
                                Slider(value: $posY, in: 0.0...1.0, step: 0.05)
                                Text("\(String(format: "Y: %.2f", posY))")
                            }
                            VStack {
                                Slider(value: $posZ, in: 0.0...1.0, step: 0.05)
                                Text("\(String(format: "Z: %.2f", posZ))")
                            }
                            Spacer()
                        }
                    }
                    .padding()
                    .foregroundColor(.white)
                    .background(.black.opacity(blackOpacity))
                    
                    Rectangle()
                        .foregroundColor(.black.opacity(blackOpacity))
                        .frame(height: 10)
                    
                    // Footer - Tab navigation
                    HStack {
                        Spacer()
                        VStack {
                            Image(systemName: "display")
                                .font(.system(size: 21))
                            Spacer()
                            Text("Demonstration")
                                .font(.system(size: 10))
                        }
                        Spacer()
                        VStack {
                            Image(systemName: "slider.horizontal.3")
                                .font(.system(size: 21))
                            Spacer()
                            Text("Preferences")
                                .font(.system(size: 10))
                        }
                        Spacer()
                    }
                    .frame(height: 20)
                    .padding()
                    .foregroundColor(.white)
                    .background(.black.opacity(blackOpacity))
                    
                    // Footer - Bottom margin
                    Rectangle()
                        .foregroundColor(.black.opacity(0))
                        .frame(height: safeAreaHeightBottom)
                }
            }
            Spacer()
        }
        .edgesIgnoringSafeArea(.all)
    }
}

struct MainUIView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView().previewDisplayName("ContentView")
        //MainUIView().previewDisplayName("MainUIView")
    }
}
