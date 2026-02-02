//
//  ViewController.swift
//  Metis
//
//  Created by Lukas Raffelt on 02.02.26.
//

import Cocoa
import MetalKit

class ViewController: NSViewController {
    var metalView: MTKView!
    var renderer: MetalRenderer!
    var lastMousePosition: NSPoint?
    var isDragging = false
    var isRightMouseDown = false  // Für Translation


    override func viewDidLoad() {
        super.viewDidLoad()
        setupMetalView()
    }

    func setupMetalView() {
        metalView = MTKView(frame: view.bounds)
        metalView.autoresizingMask = [.width, .height]
        view.addSubview(metalView)
        renderer = MetalRenderer(metalView: metalView)
    }
  
    override func mouseDown(with event: NSEvent) {
        lastMousePosition = event.locationInWindow
        isRightMouseDown = event.modifierFlags.contains(.control)  // Ctrl + Maus = Translation
    }

    override func mouseUp(with event: NSEvent) {
        lastMousePosition = nil
        isDragging = false
    }

    override func mouseDragged(with event: NSEvent) {
        guard let lastPosition = lastMousePosition else { return }
        let deltaX = Float(event.locationInWindow.x - lastPosition.x) * 0.01
        let deltaY = Float(event.locationInWindow.y - lastPosition.y) * 0.01

        if isRightMouseDown {
            // Translation (mit rechter Maustaste oder Ctrl)
            renderer.translationX += deltaX
            renderer.translationY -= deltaY
        } else {
            // Rotation
            renderer.rotationY += deltaX
            renderer.rotationX += deltaY
        }
        lastMousePosition = event.locationInWindow
    }

    override func rightMouseDragged(with event: NSEvent) {
        mouseDragged(with: event)  // Gleiche Logik wie linke Maus
    }

    override func scrollWheel(with event: NSEvent) {
        // Zoom (Translation auf Z-Achse)
        renderer.translationZ += Float(event.scrollingDeltaY) * 0.05
    }

}
