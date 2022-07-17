//
//  MainUIView.swift
//  mt-test-1
//
//  Created by Kevin Bein on 28.04.22.
//

import SwiftUI
import Combine
import RealityKit

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
    
    enum Model: String, CaseIterable, Identifiable {
        case mansion, pipe, bowlingpin, giebeldach, braunbaer, braunbaerVertical
        var id: Self { self }
    }
    @State private var activeModelName: Model = .mansion
    @State private var debugMode: Bool = false
    
    @State private var showAbout = false
    
    @State private var blurSigma = 10.0
    
    @State private var posX = 0.5
    @State private var posY = 0.5
    @State private var posZ = 0.5
    
    func onButton1() { NotificationCenter.default.post(name: Notification.Name("Button1Pressed"), object: self) }
    func onButton2() { NotificationCenter.default.post(name: Notification.Name("Button2Pressed"), object: self) }
    func onButton3() { NotificationCenter.default.post(name: Notification.Name("Button3Pressed"), object: self) }
    func onButton4() { NotificationCenter.default.post(name: Notification.Name("Button4Pressed"), object: self) }
    func onButton5() { NotificationCenter.default.post(name: Notification.Name("Button5Pressed"), object: self) }
    func onButton6() { NotificationCenter.default.post(name: Notification.Name("Button6Pressed"), object: self) }
    func onButton7() { NotificationCenter.default.post(name: Notification.Name("Button7Pressed"), object: self) }
    func onButton8() { NotificationCenter.default.post(name: Notification.Name("Button8Pressed"), object: self) }
    
    func onSlider1(_ value: Double) { NotificationCenter.default.post(name: Notification.Name("Slider1Changed"), object: self, userInfo: ["value": value]) }
    func onSlider2(_ value: Double) { NotificationCenter.default.post(name: Notification.Name("Slider2Changed"), object: self, userInfo: ["value": value]) }
    func onSlider3(_ value: Double) { NotificationCenter.default.post(name: Notification.Name("Slider3Changed"), object: self, userInfo: ["value": value]) }
    
    func onPicker1(_ value: Model) { NotificationCenter.default.post(name: Notification.Name("Picker1Changed"), object: self, userInfo: ["value": value.rawValue]) }
    
    func onToggle1(_ value: Bool) { NotificationCenter.default.post(name: Notification.Name("Toggle1Changed"), object: self, userInfo: ["value": value]) }
    
    var body: some View {
        
        let content = EmptyView()
        
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
                        
                        HStack {
                            Spacer()
                            Text("Blurring (sigma)")
                            Slider(value: $blurSigma, in: 1...50, step: 1).onChange(of: blurSigma, perform: onSlider1)
                            Text("\(String(format: "%d", Int(blurSigma)))")
                            Spacer()
                        }
                        
                        // Footer - Controls - Buttons
                        HStack {
                            PrimaryButton(title: "Blurring", action: onButton5)
                            PrimaryButton(title: "Floaters", action: onButton6)
                            PrimaryButton(title: "[unused]", action: onButton7)
                            PrimaryButton(title: "[unused]", action: onButton8)
                        }
                        .aspectRatio(contentMode: .fit)
                        // Footer - Controls - Buttons
                        HStack {
                            PrimaryButton(title: "Raw", action: onButton1)
                            PrimaryButton(title: "BG Effect", action: onButton2)
                            PrimaryButton(title: "Post (Inv)", action: onButton3)
                            PrimaryButton(title: "Reset", action: onButton4)
                        }
                        .aspectRatio(contentMode: .fit)
                        HStack {
                            Picker("Model", selection: $activeModelName) {
                                Text("Mansion").tag(Model.mansion)
                                Text("Pipe").tag(Model.pipe)
                                Text("Braunbär").tag(Model.braunbaer)
                                Text("Braunbär Vertikal").tag(Model.braunbaerVertical)
                            }
                            .accentColor(.white)
                            .onChange(of: activeModelName, perform: onPicker1)
                            .padding([.leading, .trailing], 20)
                            
                            Toggle("Debug", isOn: $debugMode)
                                .onChange(of: debugMode, perform: onToggle1)
                                .frame(width: 130, height: 30, alignment: .center)
                                .padding([.leading, .trailing], 20)
                            
                        }
                        .aspectRatio(contentMode: .fit)
                        // Footer - Controls - Sliders
                        /*HStack {
                            Spacer()
                            VStack {
                                Slider(value: $posX, in: 0.0...1.0, step: 0.05).onChange(of: posX, perform: onSlider1)
                                Text("\(String(format: "X: %.2f", posX))")
                            }
                            VStack {
                                Slider(value: $posY, in: 0.0...1.0, step: 0.05).onChange(of: posY, perform: onSlider2)
                                Text("\(String(format: "Y: %.2f", posY))")
                            }
                            VStack {
                                Slider(value: $posZ, in: 0.0...1.0, step: 0.05).onChange(of: posZ, perform: onSlider3)
                                Text("\(String(format: "Z: %.2f", posZ))")
                            }
                            Spacer()
                        }*/
                    }
                    .padding()
                    .foregroundColor(.white)
                    .background(.black.opacity(blackOpacity))
                    
                    // Footer - Tab navigation
                    
                    /*
                     Rectangle()
                         .foregroundColor(.black.opacity(blackOpacity))
                         .frame(height: 10)
                     
                     HStack {
                        Spacer()
                        VStack {
                            Image(systemName: "display")
                                .font(.system(size: 21))
                            Spacer()
                            Text("Demonstration")
                                .font(.system(size: 10))
                        }
                            .padding()
                            .foregroundColor(.blue)
                        Spacer()
                        VStack {
                            Image(systemName: "slider.horizontal.3")
                                .font(.system(size: 21))
                            Spacer()
                            Text("Preferences")
                                .font(.system(size: 10))
                        }.padding()
                        Spacer()
                    }
                    .frame(height: 20)
                    .padding()
                    .foregroundColor(.white)
                    .background(.black.opacity(blackOpacity))
                     */
                    
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
        ContentView().previewDisplayName("ContentView").previewInterfaceOrientation(.portrait)
    }
}
