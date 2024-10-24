//
//  UniversalOverlay.swift
//  SwiftUIUniversalView
//
//  Created by 김정민 on 10/24/24.
//

import SwiftUI

/// Extensions
extension View {
    @ViewBuilder
    func universalOverlay<Content: View>(
        animation: Animation = .snappy,
        show: Binding<Bool>,
        @ViewBuilder content: @escaping () -> Content
    ) -> some View {
        self
            .modifier(
                UniversalOverlayModifier(
                    animation: animation,
                    show: show,
                    viewContent: content
                )
            )
    }
}

/// Root View Wrapper
/// In order to place views on top of the SwiftUI app, we need to create an overlay window on top of the active key window. This RootView wrapper will create an overlay window, which allows us to place our views on top of the current key window.
/// To make this work, you will have to wrap your app's entry view with this wrapper.
struct RootView<Content: View>: View {
    var content: Content
    
    init(@ViewBuilder content: @escaping () -> Content) {
        self.content = content()
    }
    
    private var properties = UniversalOverlayProperties()
    
    var body: some View {
        self.content
            .environment(self.properties)
            .onAppear {
                if let windowScene = (UIApplication.shared.connectedScenes.first as? UIWindowScene),
                   self.properties.window == nil {
                    
                    let window = PassThroughView(windowScene: windowScene)
                    window.isHidden = false
                    window.isUserInteractionEnabled = true
                    
                    /// Setting Up SwiftUI Based RootView Controller
                    let rootViewController = UIHostingController(rootView: UniversalOverlayViews().environment(self.properties))
                    rootViewController.view.backgroundColor = .red.withAlphaComponent(0.3)
                    window.rootViewController = rootViewController
                    
                    self.properties.window = window
                }
            }
        
    }
}

/// Shared Universal Overlay Properties
@Observable
class UniversalOverlayProperties {
    var window: UIWindow?
    var views: [OverlayView] = []
    
    struct OverlayView: Identifiable {
        var id: String = UUID().uuidString
        var view: AnyView
    }
}

fileprivate struct UniversalOverlayModifier<ViewContent: View>: ViewModifier {
    
    var animation: Animation
    
    @Binding var show: Bool
    @ViewBuilder var viewContent: ViewContent
    
    /// Local View Properties
    @Environment(UniversalOverlayProperties.self) private var properties
    @State private var viewID: String?
    
    func body(content: Content) -> some View {
        content
            .onChange(of: self.show) { oldValue, newValue in
                if newValue {
                    self.addView()
                } else {
                    self.removewView()
                }
            }
    }
    
    private func addView() {
        if self.properties.window != nil && self.viewID == nil {
            self.viewID = UUID().uuidString
            guard let viewID else { return }
            
            withAnimation(self.animation) {
                self.properties.views.append(.init(id: viewID, view: .init(self.viewContent)))
            }
        }
    }
    
    private func removewView() {
        if let viewID {
            withAnimation(self.animation) {
                self.properties.views.removeAll(where: { $0.id == viewID })
            }
            
            self.viewID = nil
        }
    }
}

fileprivate struct UniversalOverlayViews: View {
    
    @Environment(UniversalOverlayProperties.self) private var properties
    
    var body: some View {
        ZStack {
            ForEach(self.properties.views) {
                $0.view
            }
        }
    }
}

fileprivate class PassThroughView: UIWindow {
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        guard let hitView = super.hitTest(point, with: event),
              let rootView = rootViewController?.view
        else { return nil }
        
        if #available(iOS 18, *) {
            for subview in rootView.subviews.reversed() {
                /// Finding if any of rootview's is receiving hit test
                let pointInSubview = subview.convert(point, from: rootView)
                
                if subview.hitTest(pointInSubview, with: event) == subview {
                    return hitView
                }
            }
            
            return nil
        } else {
            return hitView == rootView ? nil : hitView
        }
    }
}


#Preview {
    /// NOTE:
    /// If you want previews to be working, then you mus need to wrap your preview view with the RootView Wrapper.
    RootView {
        ContentView()
    }
}
