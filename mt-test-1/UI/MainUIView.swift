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
        var description: String {
            switch self {
            case .mansion: return "Mansion"
            case .pipe: return "Pipe"
            case .bowlingpin: return "Bowling Pin"
            case .giebeldach: return "Giebeldach"
            case .braunbaer: return "Braunbär"
            case .braunbaerVertical: return "Braunbär Vertikal"
            }
        }
    }
    @State private var activeModelName: Model = .mansion
    
    enum Simulation: String, CaseIterable, Identifiable {
        case none, blurring, floaters, macularDegeneration, glaucoma, protanomaly, deuteranomaly, tritanomaly
        var id: Self { self }
        var description: String {
            switch self {
            case .none: return "-"
            case .blurring: return "Blurring"
            case .floaters: return "Floaters"
            case .macularDegeneration: return "Macular Degeneration"
            case .glaucoma: return "Glaucoma"
            case .protanomaly: return "CVD - Protanomaly"
            case .deuteranomaly: return "CVD - Deuteranomaly"
            case .tritanomaly: return "CVD - Tritanomaly"
            }
        }
    }
    @State private var activeSimulationName: Simulation = .none
    
    enum Correction: String, CaseIterable, Identifiable, CustomStringConvertible {
        case none, contrast, colorRedBlue, brightness
        var id: Self { self }
        var description: String {
            switch self {
            case .none: return "-"
            case .contrast: return "Contrast"
            case .colorRedBlue: return "Color Red Blue"
            case .brightness: return "Brightness"
            }
        }
    }
    @State private var activeCorrectionName: Correction = .none
    
    @State private var debugMode: Bool = false
    
    @State private var showAbout = false
    @State private var showFooter = true
    
    @State private var blurringSigma = 10.0
    @State private var protanomalyPhi = 1.0
    @State private var deuteranomalyPhi = 1.0
    @State private var tritanomalyPhi = 1.0
    
    @State private var posX = 0.5
    @State private var posY = 0.5
    @State private var posZ = 0.5
    
    
    func onButtonReload() { NotificationCenter.default.post(name: Notification.Name("ButtonReloadPressed"), object: self) }
    func onButtonResetSession() { NotificationCenter.default.post(name: Notification.Name("ButtonResetSessionPressed"), object: self) }
    
    // Old
    func onButton1() { NotificationCenter.default.post(name: Notification.Name("Button1Pressed"), object: self) }
    func onButton2() { NotificationCenter.default.post(name: Notification.Name("Button2Pressed"), object: self) }
    func onButton3() { NotificationCenter.default.post(name: Notification.Name("Button3Pressed"), object: self) }
    func onButton4() { NotificationCenter.default.post(name: Notification.Name("Button4Pressed"), object: self) }
    func onButton5() { NotificationCenter.default.post(name: Notification.Name("Button5Pressed"), object: self) }
    func onButton6() { NotificationCenter.default.post(name: Notification.Name("Button6Pressed"), object: self) }
    func onButton7() { NotificationCenter.default.post(name: Notification.Name("Button7Pressed"), object: self) }
    func onButton8() { NotificationCenter.default.post(name: Notification.Name("Button8Pressed"), object: self) }
    
    func onSliderBlurringSigma(_ value: Double) { NotificationCenter.default.post(name: Notification.Name("SliderBlurringSigmaChanged"), object: self, userInfo: ["value": value]) }
    func onSliderProtanomalyPhi(_ value: Double) { NotificationCenter.default.post(name: Notification.Name("SliderProtanomalyPhiChanged"), object: self, userInfo: ["value": value]) }
    func onSliderDeuteranomalyPhi(_ value: Double) { NotificationCenter.default.post(name: Notification.Name("SliderDeuteranomalyPhiChanged"), object: self, userInfo: ["value": value]) }
    func onSliderTritanomalyPhi(_ value: Double) { NotificationCenter.default.post(name: Notification.Name("SliderTritanomalyPhiChanged"), object: self, userInfo: ["value": value]) }
    
    func onPickerModel(_ value: Model) { NotificationCenter.default.post(name: Notification.Name("PickerModelChanged"), object: self, userInfo: ["value": value.rawValue]) }
    func onPickerSimulation(_ value: Simulation) { NotificationCenter.default.post(name: Notification.Name("PickerSimulationChanged"), object: self, userInfo: ["value": value.rawValue]) }
    func onPickerCorrection(_ value: Correction) { NotificationCenter.default.post(name: Notification.Name("PickerCorrectionChanged"), object: self, userInfo: ["value": value.rawValue]) }
    
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
                        .padding([ .leading ], 20)
                    
                    Spacer()
                    
                    Button(action: onButtonResetSession) {
                        Label("", systemImage: "arrow.clockwise.circle")
                            .font(.title)
                            .foregroundColor(.blue)
                    }
                    
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
                
                // Footer
                Group {
                    
                    VStack {
                        if !showFooter {

                            // Footer Open - Controls
                            VStack {
                                // Show Footer
                                HStack {
                                    Button {
                                        showFooter = true
                                    } label: {
                                        Label("Options", systemImage: "chevron.up")
                                            .labelStyle(.iconOnly)
                                            .font(.headline)
                                    }
                                    .frame(width: UIScreen.main.bounds.width)
                                }
                                .padding([.top], 20)
                            }
                            
                        }
                        // Footer Open - Top margin
                        else {
                            
                            // Footer - Controls
                            VStack {
                                
                                // Hide Footer
                                HStack {
                                    Button {
                                        showFooter = false
                                    } label: {
                                        Label("Hide", systemImage: "chevron.down")
                                            .labelStyle(.iconOnly)
                                            .font(.headline)
                                    }
                                }
                                .padding([.bottom], 30)
                                .padding([.top], 20)
                                
                                // Model
                                HStack {
                                    Image(systemName: "house")
                                    Picker("Model (M)", selection: $activeModelName) {
                                        ForEach(Model.allCases.reversed(), id: \.id) { value in
                                            Text("M: \(value.description)")
                                        }
                                    }
                                    .accentColor(.blue)
                                    .onChange(of: activeModelName, perform: onPickerModel)
                                }
                                
                                // Simulation
                                HStack {
                                    Image(systemName: "bolt")
                                    Picker("Simulation (S)", selection: $activeSimulationName) {
                                        ForEach(Simulation.allCases.reversed(), id: \.id) { value in
                                            Text("S: \(value.description)")
                                        }
                                    }
                                    .accentColor(.blue)
                                    .onChange(of: activeSimulationName, perform: onPickerSimulation)
                                    
                                }
                                .aspectRatio(contentMode: .fit)
                                
                                // Correction - Single
                                HStack {
                                    Image(systemName: "checkmark")
                                    Picker("Correction (C)", selection: $activeCorrectionName) {
                                        ForEach(Correction.allCases.reversed(), id: \.id) { value in
                                            Text("C: \(value.description)")
                                        }
                                    }
                                    .accentColor(.blue)
                                    .onChange(of: activeCorrectionName, perform: onPickerCorrection)
                                    
                                }
                                .aspectRatio(contentMode: .fit)
                                
                                Rectangle()
                                    .foregroundColor(.black.opacity(0.0))
                                    .frame(height: 20)
                                
                                HStack {
                                    Text("Options:")
                                        .font(.headline)
                                        .multilineTextAlignment(.leading)
                                }
                                
                                // Options:
                                
                                switch activeSimulationName {
                                case .blurring:
                                    HStack {
                                        Spacer()
                                        Text("S: Blurring Σ")
                                        Slider(value: $blurringSigma, in: 1...50, step: 1).onChange(of: blurringSigma, perform: onSliderBlurringSigma)
                                        Text("\(String(format: "%d", Int(blurringSigma)))")
                                        Spacer()
                                    }
                                case .floaters:
                                    EmptyView()
                                case .macularDegeneration:
                                    EmptyView()
                                case .glaucoma:
                                    EmptyView()
                                case .protanomaly:
                                    HStack {
                                        Spacer()
                                        Text("S: Severity Φ")
                                        Slider(value: $protanomalyPhi, in: 0.0...1.0, step: 0.1).onChange(of: protanomalyPhi, perform: onSliderProtanomalyPhi)
                                        Text("\(String(format: "%.1f", protanomalyPhi))")
                                        Spacer()
                                    }
                                case .deuteranomaly:
                                    HStack {
                                        Spacer()
                                        Text("S: Severity Φ")
                                        Slider(value: $deuteranomalyPhi, in: 0.0...1.0, step: 0.1).onChange(of: deuteranomalyPhi, perform: onSliderDeuteranomalyPhi)
                                        Text("\(String(format: "%.1f", deuteranomalyPhi))")
                                        Spacer()
                                    }
                                case .tritanomaly:
                                    HStack {
                                        Spacer()
                                        Text("S: Severity Φ")
                                        Slider(value: $tritanomalyPhi, in: 0.0...1.0, step: 0.1).onChange(of: tritanomalyPhi, perform: onSliderTritanomalyPhi)
                                        Text("\(String(format: "%.1f", tritanomalyPhi))")
                                        Spacer()
                                    }
                                case .none:
                                    EmptyView()
                                }
                            }
                        }
                    }
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
        ContentView()
            .previewDisplayName("ContentView")
            .previewInterfaceOrientation(.portrait)
            .previewDevice(PreviewDevice(rawValue: "iPhone 12 Pro"))
    }
}
