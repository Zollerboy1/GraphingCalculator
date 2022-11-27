//
//  TrackingAreaView.swift
//  GraphingCalculator
//
//  Created by Josef Zoller on 17.12.21.
//

import SwiftUI


extension View {
    func trackingMouse(onMove: @escaping (Point) -> Void, onEnter: @escaping () -> (), onExit: @escaping () -> (), onScroll: @escaping (Double) -> ()) -> some View {
        TrackingAreaView(content: self, onMove: onMove, onEnter: onEnter, onExit: onExit, onScroll: onScroll)
    }
}

struct TrackingAreaView<Content>: View where Content: View {
    let content: () -> Content
    
    let onMove: (Point) -> ()
    let onEnter: () -> ()
    let onExit: () -> ()
    let onScroll: (Double) -> ()
    
    init(content: @autoclosure @escaping () -> Content, onMove: @escaping (Point) -> (), onEnter: @escaping () -> (), onExit: @escaping () -> (), onScroll: @escaping (Double) -> ()) {
        self.content = content
        self.onMove = onMove
        self.onEnter = onEnter
        self.onExit = onExit
        self.onScroll = onScroll
    }
    
    init(onMove: @escaping (Point) -> (), onEnter: @escaping () -> (), onExit: @escaping () -> (), onScroll: @escaping (Double) -> (), @ViewBuilder content: @escaping () -> Content) {
        self.content = content
        self.onMove = onMove
        self.onEnter = onEnter
        self.onExit = onExit
        self.onScroll = onScroll
    }
    
    var body: some View {
        TrackingAreaRepresentable(onMove: self.onMove, onEnter: self.onEnter, onExit: self.onExit, onScroll: onScroll, content: self.content())
    }
}


struct TrackingAreaRepresentable<Content>: NSViewRepresentable where Content: View {
    let onMove: (Point) -> ()
    let onEnter: () -> ()
    let onExit: () -> ()
    let onScroll: (Double) -> ()
    
    let content: Content
    
    func makeNSView(context: Context) -> TrackingNSHostingView<Content> {
        return TrackingNSHostingView(onMove: self.onMove, onEnter: self.onEnter, onExit: self.onExit, onScroll: self.onScroll, rootView: self.content)
    }
    
    func updateNSView(_ view: TrackingNSHostingView<Content>, context: Context) {
        view.setHandlers(onMove: self.onMove, onEnter: self.onEnter, onExit: self.onExit, onScroll: self.onScroll)
    }
}


class TrackingNSHostingView<Content>: NSHostingView<Content> where Content : View {
    private var onMove: (Point) -> ()
    private var onEnter: () -> ()
    private var onExit: () -> ()
    private var onScroll: (Double) -> ()
    
    private var wasEntered = false
    
    init(onMove: @escaping (Point) -> (), onEnter: @escaping () -> (), onExit: @escaping () -> (), onScroll: @escaping (Double) -> (), rootView: Content) {
        self.onMove = onMove
        self.onEnter = onEnter
        self.onExit = onExit
        self.onScroll = onScroll
        
        super.init(rootView: rootView)
        
        setupTrackingArea()
    }
    
    required init(rootView: Content) {
        fatalError("init(rootView:) has not been implemented")
    }
    
    @objc required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    func setHandlers(onMove: @escaping (Point) -> (), onEnter: @escaping () -> (), onExit: @escaping () -> (), onScroll: @escaping (Double) -> ()) {
        self.onMove = onMove
        self.onEnter = onEnter
        self.onExit = onExit
        self.onScroll = onScroll
    }
    
    
    override func hitTest(_ point: NSPoint) -> NSView? {
        if self.bounds.contains(point) {
            return self
        }
        
        return nil
    }

    func setupTrackingArea() {
        let options: NSTrackingArea.Options = [.mouseMoved, .mouseEnteredAndExited, .activeAlways, .inVisibleRect]
        self.addTrackingArea(NSTrackingArea.init(rect: .zero, options: options, owner: self, userInfo: nil))
    }
        
    override func mouseMoved(with event: NSEvent) {
        let location = self.convert(event.locationInWindow, from: nil)
        if self.window?.contentView?.hitTest(location) == self {
            if !self.wasEntered {
                self.wasEntered = true
                DispatchQueue.main.async {
                    self.onEnter()
                }
            }
            
            DispatchQueue.main.async {
                self.onMove(Point(location))
            }
        } else {
            if self.wasEntered {
                self.wasEntered = false
                DispatchQueue.main.async {
                    self.onExit()
                }
            }
        }
    }
    
    override func mouseEntered(with event: NSEvent) {
        let location = self.convert(event.locationInWindow, from: nil)
        if self.window?.contentView?.hitTest(location) == self && !self.wasEntered {
            self.wasEntered = true
            DispatchQueue.main.async {
                self.onEnter()
            }
        }
    }
    
    override func mouseExited(with event: NSEvent) {
        if self.wasEntered {
            self.wasEntered = false
            DispatchQueue.main.async {
                self.onExit()
            }
        }
    }
    
    override func scrollWheel(with event: NSEvent) {
        if wasEntered {
            let delta = event.scrollingDeltaY
            
            self.onScroll(delta)
        }
    }
}
