//
//  MainUIView.swift
//  mt-test-1
//
//  Created by Kevin Bein on 24.04.22.
//

import SwiftUI

struct _MainUIView: View {
    @State private var showAbout = false
    
    var body: some View {
        TabView {
            HeaderView {
                Text("Demonstration")
                    // .foregroundColor(Color.white).background(Color.blue)
            }
            .tabItem {
                Image(systemName: "display")
                // Image(systemName: "move.3d")
                Text("Demonstration")
            }
            
            HeaderView {
                Text("Preferences")
            }
            .tabItem {
                Image(systemName: "slider.horizontal.3")
                Text("Preferences")
            }
        }
        
        /*VStack {
            // Text("Accessibile AR").font(.largeTitle)
            
            NavigationView {
                VStack {
                    Button(action: {
                    }) {
                        Label("Continue last session", systemImage: "arrow.right")
                    }
                    
                    NavigationLink(destination: EmptyView()) {
                        Button(action: {
                        }) {
                            Label("Load demonstration", systemImage: "folder")
                        }
                    }
                    
                    Button {
                        showAbout = true
                    } label: {
                        Label("About", systemImage: "info.circle")
                    }
                    .alert(isPresented: $showAbout) {
                        Alert(
                           title: Text("<About>"),
                           message: Text("Kevin Bein \n\nmail@kevinbein.de")
                       )
                    }
                }
            }
        }*/
    }
}

struct _MainUIView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            MainUIView()
                .previewInterfaceOrientation(.portrait)
        }
    }
}
