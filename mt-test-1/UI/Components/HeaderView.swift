//
//  HeaderView.swift
//  mt-test-1
//
//  Created by Kevin Bein on 24.04.22.
//

import SwiftUI
    
struct HeaderView<Content: View>: View {
    @State private var showAbout = false
    
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        NavigationView {
            content
            .navigationTitle(ProjectSettings.appName)
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showAbout = true
                    } label: {
                        Label("About", systemImage: "info.circle").labelStyle(.iconOnly)
                    }
                    .alert(isPresented: $showAbout) {
                        Alert(
                            title: Text(ProjectSettings.appName),
                            message: Text("""
                             
                             \(ProjectSettings.authorName)
                             \(ProjectSettings.authorEmail)
                             ©\(String(Calendar.current.component(.year, from: Date())))
                             """)
                       )
                    }
                }
            }
            //.navigationTitle("Accessible AR")
        }.background(Color.red)
    }
}

struct HeaderView_Previews: PreviewProvider {
    static var previews: some View {
        HeaderView {
            Text("<injected content>")
        }.background(Color.red)
    }
}
