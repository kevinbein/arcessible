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
        case mansion, populating_exitSignGroundStick, populating_exitSign, populating_exitSignGround, pipe, populating_beerpong, bowlingpin, giebeldach, braunbaer, braunbaerVertical, wuschel1, ninetydegreebracket, dcWhiteHouse, cinemaChair, decorativeLightPole, scaffold, realisticEuropanTree, bathroomInterior, newYorkDowntown, loft
        var id: Self { self }
        var description: String {
            switch self {
            case .mansion: return "Mansion"
            case .pipe: return "Pipe"
            case .populating_exitSign: return "Exit Sign"
            case .populating_beerpong: return "Beerpong"
            case .bowlingpin: return "Bowling Pin"
            case .giebeldach: return "Giebeldach"
            case .braunbaer: return "Braunbär"
            case .braunbaerVertical: return "Braunbär Vertikal"
            case .wuschel1: return "Wuschel 1"
            case .ninetydegreebracket: return "90 Degree Bracket"
            case .dcWhiteHouse: return "DC White House"
            case .cinemaChair: return "Cinema Chair"
            case .decorativeLightPole: return "Decorative Light Pole"
            case .scaffold: return "Scaffold"
            case .realisticEuropanTree: return "Realistic European Tree"
            case .bathroomInterior: return "Bathroom Interior"
            case .newYorkDowntown: return "New York Downtown"
            case .loft: return "Loft"
            default: return self.rawValue
            }
        }
    }
    
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
    
    enum Correction: String, CaseIterable, Identifiable, CustomStringConvertible {
        case none, edgeEnhancement, daltonization, hsbc, sobel, bgGrayscale, bgDepth, bgDepthBlurred
        var id: Self { self }
        var description: String {
            switch self {
            case .none: return "-"
            case .edgeEnhancement: return "Edge Enhancement"
            case .daltonization: return "Daltonization"
            case .hsbc: return "HSBC"
            case .bgGrayscale: return "Background W/B"
            case .bgDepth: return "Depth Visualization"
            case .bgDepthBlurred: return "Background Depth Blurred"
            case .sobel: return "Sobel"
            }
        }
    }
    
    enum EvaluationPreset: String, CaseIterable, Identifiable, CustomStringConvertible {
        case game, gameContrast, gameBlackWhite, gameCVD, gameBackground, gameBlurred, gameTight, downproject, anchorTest, depthTest, piano, spatialAwareness, mansion
        var id: Self { self }
        var description: String {
            return self.rawValue
        }
    }
    
    enum WorkMode: String, CaseIterable, Identifiable, CustomStringConvertible {
        case debug, evaluation, statistics, populateScene
        var id: Self { self }
        var description: String {
            return self.rawValue
        }
    }
    
    // Defaults
    @State private var activeWorkMode: WorkMode = ProjectSettings.initialWorkMode
    @State private var activeModelName: Model = ProjectSettings.initialModel
    @State private var activeSimulationName: Simulation = ProjectSettings.initialSimulation
    @State private var activeCorrectionName: Correction = ProjectSettings.initialCorrection
    @State private var activeEvaluationPreset: EvaluationPreset = ProjectSettings.initialEvaluationPreset
    
    @State private var evaluationCandidateName: String = "debug_kevin"
    
    @State private var debugMode: Bool = false
    
    @State private var showAbout = false
    @State private var showFooterDebugSettings = true
    @State private var showCandidateName = false
    
    @State private var blurringSigma = 10.0
    @State private var protanomalyPhi = 1.0
    @State private var deuteranomalyPhi = 1.0
    @State private var tritanomalyPhi = 1.0
    
    @State private var hue = 0.0
    @State private var saturation = 0.5
    @State private var brightness = 0.5
    @State private var contrast = 0.5
    
    @State private var posX = 0.5
    @State private var posY = 0.5
    @State private var posZ = 0.5
    
    func onButtonResetSession() { NotificationCenter.default.post(name: Notification.Name("ButtonResetSessionPressed"), object: self) }
    func onButtonScreenshot() { NotificationCenter.default.post(name: Notification.Name("ButtonScreenshotPressed"), object: self) }
    func onButtonStartEvaluation() { NotificationCenter.default.post(name: Notification.Name("ButtonStartEvaluationPressed"), object: self) }
    func onButtonAbortEvaluation() { NotificationCenter.default.post(name: Notification.Name("ButtonAbortEvaluationPressed"), object: self) }
    
    func onButtonPrintLog() { NotificationCenter.default.post(name: Notification.Name("ButtonPrintEvaluationLogPressed"), object: self) }
    func onButtonTest() { NotificationCenter.default.post(name: Notification.Name("ButtonTestPressed"), object: self) }
    
    func onSliderBlurringSigma(_ value: Double) { NotificationCenter.default.post(name: Notification.Name("SliderBlurringSigmaChanged"), object: self, userInfo: ["value": value]) }
    func onSliderProtanomalyPhi(_ value: Double) { NotificationCenter.default.post(name: Notification.Name("SliderProtanomalyPhiChanged"), object: self, userInfo: ["value": value]) }
    func onSliderDeuteranomalyPhi(_ value: Double) { NotificationCenter.default.post(name: Notification.Name("SliderDeuteranomalyPhiChanged"), object: self, userInfo: ["value": value]) }
    func onSliderTritanomalyPhi(_ value: Double) { NotificationCenter.default.post(name: Notification.Name("SliderTritanomalyPhiChanged"), object: self, userInfo: ["value": value]) }
    func onSliderHSBC(_ value: Double) {
        let hsbc = [ "hue": hue, "saturation": saturation, "brightness": brightness, "contrast": contrast ]
        NotificationCenter.default.post(name: Notification.Name("SliderHSBCChanged"), object: self, userInfo: hsbc)
        Log.print("HSBC: ", hsbc)
    }
    
    func onPickerModel(_ value: Model) { NotificationCenter.default.post(name: Notification.Name("PickerModelChanged"), object: self, userInfo: ["value": value.rawValue]) }
    func onPickerSimulation(_ value: Simulation) { NotificationCenter.default.post(name: Notification.Name("PickerSimulationChanged"), object: self, userInfo: ["value": value.rawValue]) }
    func onPickerCorrection(_ value: Correction) { NotificationCenter.default.post(name: Notification.Name("PickerCorrectionChanged"), object: self, userInfo: ["value": value.rawValue]) }
    func onPickerEvaluationPreset(_ value: EvaluationPreset) { NotificationCenter.default.post(name: Notification.Name("PickerEvaluationPresetChanged"), object: self, userInfo: ["value": value.rawValue]) }
    func onButtonWorkMode(_ value: WorkMode) { NotificationCenter.default.post(name: Notification.Name("WorkModeChange"), object: self, userInfo: ["value": value.rawValue ]) }
    
    func onToggle1(_ value: Bool) { NotificationCenter.default.post(name: Notification.Name("Toggle1Changed"), object: self, userInfo: ["value": value]) }
    
    let reloadPipeline = NotificationCenter.default.publisher(for: NSNotification.Name("PipelineReload"))
    func onReloadPipeline() {
        onPickerSimulation(activeSimulationName)
        onPickerCorrection(activeCorrectionName)
        onPickerEvaluationPreset(activeEvaluationPreset)
        Log.print("Pipeline reloaded")
    }
    
    let arViewLoaded = NotificationCenter.default.publisher(for: NSNotification.Name("ARViewInitialized"))
    func onARViewLoaded() {
        Log.print("onARViewLoaded")
        onReloadPipeline()
        onButtonWorkMode(activeWorkMode)
    }
    
    fileprivate func HorizontalSpacingView(height: CGFloat = 20) -> some View {
        Rectangle()
            .foregroundColor(.black.opacity(0.0))
            .frame(height: height)
    }
    
    fileprivate func HeaderIconButton(systemImage: String, action: @escaping () -> ()) -> Button<some View> {
        return Button(action: action) {
            Label("", systemImage: systemImage)
                .font(.title)
                .foregroundColor(.blue)
        }
    }
    
    fileprivate func Header() -> some View {
        return // Header - Title
        HStack {
            Text(ProjectSettings.appName)
                .font(.largeTitle)
                .bold()
                .foregroundColor(.white)
                .padding([ .leading ], 20)
            
            Spacer()
            
            HeaderIconButton(systemImage: "arrow.clockwise.circle", action: onButtonResetSession)
            HeaderIconButton(systemImage: "info.circle", action: {
                showAbout = true
            })
            .alert(isPresented: $showAbout) {
                Alert(
                    title: Text("About"),
                    message: Text("\n\(ProjectSettings.authorName)\n\(ProjectSettings.authorEmail)")
                )
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.all)
        .background(.black.opacity(ProjectSettings.uiBackgroundOpacity))
    }
    
    fileprivate func FooterTabSelection() -> some View {
        return // Tab selection
        Group {
            // Evaluation
            HStack {
                Spacer()
                PrimaryButton(title: "Evaluation", action: {
                    activeWorkMode = .evaluation
                    onButtonWorkMode(activeWorkMode)
                })
                PrimaryButton(title: "Debug", action: {
                    activeWorkMode = .debug
                    onButtonWorkMode(activeWorkMode)
                })
                PrimaryButton(title: "Populate", action: {
                    activeWorkMode = .populateScene
                    onButtonWorkMode(activeWorkMode)
                })
                /*PrimaryButton(title: "St.", action: {
                    activeWorkMode = .statistics
                    onButtonWorkMode(activeWorkMode)
                })*/
                Spacer()
            }
            //.padding([.bottom], 50)
            //.padding([.top], 50)
            .frame(height: 20)
            .aspectRatio(contentMode: .fit)
            .padding()
            .foregroundColor(.white)
        }
    }
    
    @State var countdownIsActive = false
    @State var evaluationIsInProgress = false
    @State var countdown = ProjectSettings.evaluationStartCountdown
    fileprivate func CountdownView() -> some View {
        let countdownTimer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
        return Group {
            if countdownIsActive {
                VStack {
                    Text("Start in \(countdown)").font(.largeTitle)
                }
                .padding(50)
                .foregroundColor(.white)
                .background(.black.opacity(ProjectSettings.uiBackgroundOpacity))
            } else {
                EmptyView()
            }
        }
        .onReceive(countdownTimer) { _ in
            if countdownIsActive {
                countdown -= 1
                if countdown <= 0 {
                    NotificationCenter.default.post(name: Notification.Name("EvaluationStart"), object: self)
                    countdownIsActive = false
                    evaluationIsInProgress = true
                    countdown = ProjectSettings.evaluationStartCountdown
                    //countdownTimer.upstream.connect().cancel()
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("ButtonStartEvaluationPressed"))) { object in
            if evaluationCandidateName.count > 0 {
                countdownIsActive = true
                NotificationCenter.default.post(name: Notification.Name("EvaluationInit"), object: self, userInfo: ["value": [activeEvaluationPreset.rawValue, evaluationCandidateName]])
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("EvaluationAborted"))) { object in
            countdownIsActive = false
            countdown = ProjectSettings.evaluationStartCountdown
            evaluationIsInProgress = false
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("EvaluationEnded"))) { object in
            countdownIsActive = false
            countdown = ProjectSettings.evaluationStartCountdown
            evaluationIsInProgress = false
        }
    }
    
    fileprivate func FooterTabEvaluation() -> some View {
        return Group {
            VStack {
                HStack {
                    Spacer()
                    if !evaluationIsInProgress {
                        PrimaryButton(title: "Start", action: onButtonStartEvaluation)
                        PrimaryButton(title: "Test", action: onButtonTest)
                        PrimaryButton(title: "Log", action: onButtonPrintLog)
                    } else {
                        PrimaryButton(title: "Abort Evaluation", action: onButtonAbortEvaluation)
                    }
                    Spacer()
                }
                .frame(height: 20)
                .aspectRatio(contentMode: .fit)
                .padding()
                .foregroundColor(.white)
                
                if !evaluationIsInProgress {
                    HStack {
                        Spacer()
                        PrimaryButton(title: "Set candidate name") {
                            showCandidateName = true
                        }
                        .alert("Candidate Name", isPresented: $showCandidateName, actions: {
                            TextField("Candidate Name", text: $evaluationCandidateName).foregroundColor(.black)
                            Button("OK", action: {})
                        }, message: {
                            Text("Please specify the candidate name.")
                        })
                        let name = evaluationCandidateName.count > 0 ? evaluationCandidateName : "<empty>"
                        Text(name)
                        Spacer()
                    }
                    .frame(height: 20)
                    .aspectRatio(contentMode: .fit)
                    .padding()
                    
                    HStack {
                        Text("Preset")
                        Picker("Correction (C)", selection: $activeEvaluationPreset) {
                            ForEach(EvaluationPreset.allCases.reversed(), id: \.id) { value in
                                Text("E: \(value.description)")
                            }
                        }
                        .accentColor(.blue)
                        .onChange(of: activeEvaluationPreset, perform: onPickerEvaluationPreset)
                    }
                }
            }
        }
    }
    
    @State var visualNotificationOpacity: Double = 0.0
    @State var visualNotificationColor: Color = .red
    fileprivate func VisualNotificationView() -> some View {
        let visualNotificationTimer = Timer.publish(every: 0.002, on: .main, in: .common).autoconnect()
        return Group {
            if self.visualNotificationOpacity > 0.0 {
                RoundedRectangle(cornerRadius: 50)
                //.border(.red, width: 4)
                    .stroke(visualNotificationColor, lineWidth: 10)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .opacity(visualNotificationOpacity)
            } else {
                EmptyView()
            }
        }
        .onReceive(visualNotificationTimer) { timer in
            visualNotificationOpacity = max(0.0, visualNotificationOpacity - 0.05)
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("VisualNotification"))) { notification in
            visualNotificationColor = notification.userInfo?["color"] as? Color ?? .red
            visualNotificationOpacity = 1.0
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("EvaluationHitFailure"))) { notification in
            evaluationHitStatus = notification.userInfo?["status"] as? String ?? "failure"
            evaluationHitDistance = notification.userInfo?["distance"] as? Float ?? -1.0
            Log.print("Notification.EvaluationHitFailure: \(evaluationHitStatus), \(evaluationHitDistance)")
            NotificationCenter.default.post(name: Notification.Name("VisualNotification"), object: self, userInfo: ["color": Color.red])
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("EvaluationHitSuccess"))) { notification in
            evaluationHitStatus = notification.userInfo?["status"] as? String ?? "failure"
            evaluationHitDistance = notification.userInfo?["distance"] as? Float ?? -1.0
            Log.print("Notification.EvaluationHitSuccess: \(evaluationHitStatus), \(evaluationHitDistance)")
            NotificationCenter.default.post(name: Notification.Name("VisualNotification"), object: self, userInfo: ["color": Color.green])
        }
    }
    
    @State var evaluationHitStatus: String = ""
    @State var evaluationHitDistance: Float = -1.0
    @State var debugFrameInformation: String = ""
    fileprivate func InformationBar() -> some View {
        return Group {
            VStack(alignment: .leading) {
                HStack {
                    Text("WMP: \(MainARView.shared.session.currentFrame?.worldMappingStatus.rawValue ?? -1)").padding([.trailing], 10)
                    Text("FP: \(MainARView.shared.session.currentFrame?.rawFeaturePoints?.points.count ?? -1)").padding([.trailing], 10)
                    Text("EHS: \(evaluationHitStatus)").padding([.trailing], 10)
                    Text("ED: \(evaluationHitDistance)")
                }
                HStack {
                    Text("Frame: \(debugFrameInformation)")
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding([.horizontal], 20)
            .padding([.vertical], 10)
            .background(.black.opacity(ProjectSettings.uiBackgroundOpacity))
            .font(.caption)
            .foregroundColor(.yellow)
            .fontWeight(.bold)
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("LogUIPrint"))) { notification in
            let key = notification.userInfo?["key"] as? String ?? "failure"
            if key == "frameInformation" {
                guard let information = notification.userInfo?["value"] as? [String : Any] else { return }
                //let information = notification.userInfo?["value"] as? [String : Any]
                let worldMappingStatus = information["WMP"] as! String
                let frameNumber = information["FN"] as! Int
                // For some unknown reason, frameNumber cannot be printed without disabling all timers so we have to leave it out ...
                // (maybe it has something to do how quickly this value updates and the other timers don't have a chance to update themselves?
                if ProcessInfo.processInfo.environment["SCHEME_TYPE"] == "replay" {
                    debugFrameInformation = "WMP: \(worldMappingStatus), FN: \(String(frameNumber))"
                } else {
                    debugFrameInformation = "WMP: \(worldMappingStatus)"
                }
            }
        }
    }
    
    @State var showEvaluationResult = true
    @State var evaluationResult: EvaluationSession.SessionData?
    fileprivate func EvaluationResultView() -> some View {
        return Group {
            if evaluationResult != nil {
                HStack{}.alert("Results", isPresented: $showEvaluationResult, actions: {
                    Button("OK", action: {})
                }, message: {
                    let intermediateTimesStr: String = evaluationResult!.intermediateTimes.reduce("", {
                        "\($0)\($0.count > 0 ? ", " : "")\($1.format(differenceTo: evaluationResult!.startTime).formatDigits(2))"
                    })
                    let intermediateMissesStr: String = evaluationResult!.intermediateMisses.reduce("", {
                        "\($0)\($0.count > 0 ? ", " : "")\($1)"
                    })
                    let averageIntermediateMissDistancesStr: String = evaluationResult!.averageIntermediateMissDistances.reduce("", {
                        "\($0)\($0.count > 0 ? ", " : "")\($1)"
                    })
                    let output: String = """
                    Candidate name: \(evaluationResult!.candidateName)
                    Preset: \(evaluationResult!.evaluationPreset)
                    Min distance: \(evaluationResult!.evaluationMinDistance)
                    Intermediate Times:
                    [ \(intermediateTimesStr) ]
                    Total misses: \(evaluationResult!.totalMisses)
                    Intermediate Misses:
                    [ \(intermediateMissesStr) ]
                    Average Miss Distance: \(evaluationResult!.averageMissDistance)
                    Average Intermediate Miss Distances:
                    [ \(averageIntermediateMissDistancesStr) ]
                    Total time: \(evaluationResult!.duration.formatDigits(2))
                    """
                    Text(output).multilineTextAlignment(.leading)
                })
            } else {
                EmptyView()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("EvaluationEnded"))) { notification in
            guard let evaluationResult = notification.userInfo?["sessionData"] as? EvaluationSession.SessionData else { return }
            self.showEvaluationResult = true
            self.evaluationResult = evaluationResult
        }
    }
    
    fileprivate func Footer() -> some View {
        return Group {
            VStack {
                if !evaluationIsInProgress {
                    FooterTabSelection()
                    //HorizontalSpacingView(height: 10)
                }
                
                if activeWorkMode == .evaluation {
                    FooterTabEvaluation()
                }
                else if !showFooterDebugSettings, activeWorkMode == .debug {
                    // Footer Open - Controls
                        // Show Footer
                    HStack {
                        Button {
                            showFooterDebugSettings = true
                        } label: {
                            Label("Options", systemImage: "chevron.up")
                                .labelStyle(.iconOnly)
                                .font(.headline)
                        }
                        .frame(width: UIScreen.main.bounds.width)
                    }
                    .padding([.top], 20)
                }
                // Footer Open - Top margin
                else if activeWorkMode == .debug {
                    // Footer - Controls
                        // Hide Footer
                        /*HStack {
                            Button {
                                showFooterDebugSettings = false
                            } label: {
                                Label("Hide", systemImage: "chevron.down")
                                    .labelStyle(.iconOnly)
                                    .font(.headline)
                            }
                        }
                        .padding([.bottom], 30)
                        .padding([.top], 20)*/
                        
                        // Picker - Model
                        HStack {
                            Image(systemName: "house")
                            Picker("Model (M)", selection: $activeModelName) {
                                ForEach(Model.allCases.reversed(), id: \.id) { value in
                                    Text("M: \(value.description)")
                                }
                            }
                            .accentColor(.blue)
                            .onChange(of: activeModelName, perform: onPickerModel)
                        }.frame(maxWidth: .infinity)
                        
                        // Picker - Correction
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
                        .frame(maxWidth: .infinity)
                        
                        // Picker - Simulation
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
                        .frame(maxWidth: .infinity)
                        
                        HorizontalSpacingView()
                        
                        // Options label
                        
                        HStack {
                            Text("Options:")
                                .font(.headline)
                                .multilineTextAlignment(.leading)
                        }
                        
                        // Options:
                        switch activeCorrectionName {
                        case .hsbc:
                            VStack {
                                HStack {
                                    Spacer()
                                    Text("H")
                                    Slider(value: $hue, in: 0.0...1.0, step: 0.05).onChange(of: hue, perform: onSliderHSBC)
                                    Text("\(String(format: "%.1f", hue))")
                                    Spacer()
                                    Text("S")
                                    Slider(value: $saturation, in: 0.0...1.0, step: 0.05).onChange(of: saturation, perform: onSliderHSBC)
                                    Text("\(String(format: "%.1f", saturation))")
                                    Spacer()
                                }
                                HStack {
                                    Spacer()
                                    Text("B")
                                    Slider(value: $brightness, in: 0.0...1.0, step: 0.05).onChange(of: brightness, perform: onSliderHSBC)
                                    Text("\(String(format: "%.1f", brightness))")
                                    Spacer()
                                    Text("C")
                                    Slider(value: $contrast, in: 0.0...1.0, step: 0.05).onChange(of: contrast, perform: onSliderHSBC)
                                    Text("\(String(format: "%.1f", contrast))")
                                    Spacer()
                                }
                            }
                        case .none:
                            EmptyView()
                        case .daltonization:
                            EmptyView()
                        case .sobel:
                            EmptyView()
                        case .bgGrayscale:
                            EmptyView()
                        case .edgeEnhancement:
                            EmptyView()
                        case .bgDepth:
                            EmptyView()
                        case .bgDepthBlurred:
                            EmptyView()
                        }
                        
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
            .padding()
            .foregroundColor(.white)
            .background(.black.opacity(ProjectSettings.uiBackgroundOpacity))
        }
    }
    
    var body: some View {
        let safeAreaHeightTop = UIApplication.shared.keyWindow?.safeAreaInsets.top
        let safeAreaHeightBottom = UIApplication.shared.keyWindow?.safeAreaInsets.bottom
        Group {
            if ProcessInfo.processInfo.environment["SCHEME_TYPE"] == "replay",
                ReplaySceneSetup.sceneOptions[ProjectSettings.replayScene]?.hideUi == true
            {
                // Nothing
                EmptyView()
            } else {
                ZStack {
                    VStack(spacing: 0) {
                        HorizontalSpacingView(height: safeAreaHeightTop!)
                        Header()
                        InformationBar()
                        Spacer()
                        CountdownView()
                        Spacer()
                        Footer()
                        HorizontalSpacingView(height: safeAreaHeightBottom!)
                    }
                    VisualNotificationView()
                    EvaluationResultView()
                    Spacer()
                }
                
            }
        }
        .onLoad {
            self.onLoad()
        }
        .onReceive(arViewLoaded) { (output) in
            self.onARViewLoaded()
        }
        .onReceive(reloadPipeline) { (output) in
            self.onReloadPipeline()
        }
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
