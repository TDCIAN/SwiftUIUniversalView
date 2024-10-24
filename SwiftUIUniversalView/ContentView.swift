//
//  ContentView.swift
//  SwiftUIUniversalView
//
//  Created by 김정민 on 10/22/24.
//

import SwiftUI
import AVKit

struct ContentView: View {
    
    @State private var show: Bool = false
    @State private var showSheet: Bool = false
    @State private var text: String = ""
    
    var body: some View {
        NavigationStack {
            List {
                Button(action: {
                    self.show.toggle()
                }, label: {
                    Text("Floating Video Player")
                })
                .universalOverlay(show: self.$show) {
                    FloatingVideoPlayerView(show: self.$show)
                }
                
                Button("Show Dummy Sheet") {
                    self.showSheet.toggle()
                }
            }
            .navigationTitle("Universal Overlay")
        }
        .sheet(isPresented: self.$showSheet) {
            Text("Hello From Sheet!")
        }
    }
}

struct FloatingVideoPlayerView: View {
    @Binding var show: Bool
    /// View Properties
    @State private var player: AVPlayer?
    @State private var offset: CGSize = .zero
    @State private var lastStoredOffset: CGSize = .zero
    
    var body: some View {
        GeometryReader { geometry in
            let size = geometry.size
            
            Group {
                if let videoURL {
                    VideoPlayer(player: self.player)
                        .background(.black)
                        .clipShape(.rect(cornerRadius: 25))
                } else {
                    RoundedRectangle(cornerRadius: 25)
                }
            }
            .frame(height: 250)
            .offset(self.offset)
            .gesture(
                DragGesture()
                    .onChanged { value in
                        let translation = value.translation + self.lastStoredOffset
                        self.offset = translation
                    }
                    .onEnded { value in
                        withAnimation(.bouncy) {
                            /// Limiting to not move away from the screen
                            self.offset.width = 0
                            
                            if self.offset.height < 0 {
                                self.offset.height = 0
                            }
                            
                            if self.offset.height > (size.height - 250) {
                                self.offset.height = (size.height - 250)
                            }
                        }

                        self.lastStoredOffset = self.offset
                    }
            )
            .frame(maxHeight: .infinity, alignment: .top)
        }
        .padding(.horizontal, 15)
        .transition(.blurReplace)
        .onAppear {
            if let videoURL {
                self.player = AVPlayer(url: videoURL)
                self.player?.play()
            }
        }
    }
    
    var videoURL: URL? {
        if let bundle = Bundle.main.path(forResource: "Area", ofType: "mp4") {
            return .init(filePath: bundle)
        }
        return nil
    }
}

extension CGSize {
    static func +(lhs: CGSize, rhs: CGSize) -> CGSize {
        return .init(
            width: lhs.width + rhs.width,
            height: lhs.height + rhs.height
        )
    }
}

#Preview {
    RootView {
        ContentView()
    }
}
