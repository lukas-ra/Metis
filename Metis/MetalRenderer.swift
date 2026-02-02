//
//  MetalRenderer.swift
//  Metis
//
//  Created by Lukas Raffelt on 02.02.26.
//
// Test

import MetalKit
import simd

class MetalRenderer: NSObject, MTKViewDelegate {
    var device: MTLDevice!
    var commandQueue: MTLCommandQueue!
    var renderPipelineState: MTLRenderPipelineState!
    var vertexBuffer: MTLBuffer!
    var uniformBuffer: MTLBuffer!
    var mesh: Mesh
    var depthStencilState: MTLDepthStencilState!
    var indexBuffer: MTLBuffer! // Moved property declaration here

    // Für die Rotation
    var rotationAngle: Float = 0

    // Add these as instance properties
    var rotationX: Float = 0
    var rotationY: Float = 0
    var rotationZ: Float = 0
    var translationX: Float = 0
    var translationY: Float = 0
    var translationZ: Float = -3

    struct Uniforms {
        var modelViewProjectionMatrix: matrix_float4x4
    }

    init(metalView: MTKView) {
        mesh = Mesh.cube() // Standardmäßig ein Würfel
        super.init()
        metalView.device = MTLCreateSystemDefaultDevice()
        device = metalView.device!
        metalView.delegate = self
        metalView.clearColor = MTLClearColor(red: 0.1, green: 0.1, blue: 0.1, alpha: 1)
        metalView.depthStencilPixelFormat = .depth32Float
        setupMetal()
        setupPipeline(metalView: metalView)
        setupBuffers()
        setupDepthStencil()
    }

    func setupMetal() {
        commandQueue = device.makeCommandQueue()
    }

    func setupDepthStencil() {
        let descriptor = MTLDepthStencilDescriptor()
        descriptor.depthCompareFunction = .less
        descriptor.isDepthWriteEnabled = true
        depthStencilState = device.makeDepthStencilState(descriptor: descriptor)!
    }

    func setupPipeline(metalView: MTKView) {
        let shaderSource = """
        #include <metal_stdlib>
        using namespace metal;

        struct Uniforms {
            float4x4 modelViewProjectionMatrix;
        };

        vertex float4 vertexShader(
            device const packed_float3* positions [[buffer(0)]],
            device const Uniforms& uniforms [[buffer(1)]],
            unsigned int vid [[vertex_id]]
        ) {
            return uniforms.modelViewProjectionMatrix * float4(positions[vid], 1);
        }

        fragment float4 fragmentShader() {
            return float4(0.8, 0.3, 0.3, 1.0); // Rötliche Farbe
        }
        """
        let library = try! device.makeLibrary(source: shaderSource, options: nil)
        let vertexFunction = library.makeFunction(name: "vertexShader")
        let fragmentFunction = library.makeFunction(name: "fragmentShader")

        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        pipelineDescriptor.vertexFunction = vertexFunction
        pipelineDescriptor.fragmentFunction = fragmentFunction
        pipelineDescriptor.colorAttachments[0].pixelFormat = metalView.colorPixelFormat
        pipelineDescriptor.depthAttachmentPixelFormat = metalView.depthStencilPixelFormat

        renderPipelineState = try! device.makeRenderPipelineState(descriptor: pipelineDescriptor)
    }

    func setupBuffers() {
        vertexBuffer = device.makeBuffer(bytes: mesh.vertices, length: mesh.vertices.count * MemoryLayout<Float>.stride, options: [])
        indexBuffer = device.makeBuffer(bytes: mesh.indices, length: mesh.indices.count * MemoryLayout<UInt16>.stride, options: [])
        uniformBuffer = device.makeBuffer(length: MemoryLayout<Uniforms>.stride, options: [])
    }

    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {}

    // Helper functions for matrix operations
    func radians_from_degrees(_ degrees: Float) -> Float {
        return degrees * .pi / 180.0
    }

    func matrix_float4x4_rotation(x: Float, y: Float, z: Float) -> matrix_float4x4 {
        let rotationX = matrix_float4x4(
            [1, 0, 0, 0],
            [0, cos(x), -sin(x), 0],
            [0, sin(x), cos(x), 0],
            [0, 0, 0, 1]
        )

        let rotationY = matrix_float4x4(
            [cos(y), 0, sin(y), 0],
            [0, 1, 0, 0],
            [-sin(y), 0, cos(y), 0],
            [0, 0, 0, 1]
        )

        let rotationZ = matrix_float4x4(
            [cos(z), -sin(z), 0, 0],
            [sin(z), cos(z), 0, 0],
            [0, 0, 1, 0],
            [0, 0, 0, 1]
        )

        return rotationX * rotationY * rotationZ
    }

    func matrix_float4x4_translation(_ x: Float, _ y: Float, _ z: Float) -> matrix_float4x4 {
        return matrix_float4x4(
            [1, 0, 0, 0],
            [0, 1, 0, 0],
            [0, 0, 1, 0],
            [x, y, z, 1]
        )
    }

    func matrix_float4x4_perspective(fovy: Float, aspect: Float, near: Float, far: Float) -> matrix_float4x4 {
        let yScale = 1 / tan(fovy * 0.5)
        let xScale = yScale / aspect
        let zScale = far / (far - near)
        let zOffset = -near * far / (far - near)

        return matrix_float4x4(
            [xScale, 0, 0, 0],
            [0, yScale, 0, 0],
            [0, 0, zScale, 1],
            [0, 0, zOffset, 0]
        )
    }

    func draw(in view: MTKView) {
        guard let drawable = view.currentDrawable,
              let renderPassDescriptor = view.currentRenderPassDescriptor else { return }

        // Model-Matrix: Rotation + Translation
        let modelMatrix = matrix_float4x4_rotation(x: rotationX, y: rotationY, z: rotationZ) *
                          matrix_float4x4_translation(translationX, translationY, translationZ)

        // View-Matrix: Kamera-Position
        let viewMatrix = matrix_float4x4_translation(0, 0, 0).inverse

        // Projection-Matrix: Perspektive
        let aspect = Float(view.drawableSize.width / view.drawableSize.height)
        let projectionMatrix = matrix_float4x4_perspective(fovy: radians_from_degrees(65), aspect: aspect, near: 0.1, far: 100)

        // MVP-Matrix
        let mvpMatrix = projectionMatrix * viewMatrix * modelMatrix

        // Uniforms aktualisieren
        let uniforms = Uniforms(modelViewProjectionMatrix: mvpMatrix)
        let bufferPointer = uniformBuffer.contents().bindMemory(to: Uniforms.self, capacity: 1)
        bufferPointer.pointee = uniforms

        // Rendering (wie bisher)
        let commandBuffer = commandQueue.makeCommandBuffer()!
        let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor)!
        renderEncoder.setRenderPipelineState(renderPipelineState)
        renderEncoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
        renderEncoder.setVertexBuffer(uniformBuffer, offset: 0, index: 1)
        renderEncoder.drawIndexedPrimitives(type: .triangle, indexCount: 36, indexType: .uint16, indexBuffer: indexBuffer, indexBufferOffset: 0)
        renderEncoder.endEncoding()
        commandBuffer.present(drawable)
        commandBuffer.commit()
    }
}

// Hilfsstruktur für 3D-Objekte
struct Mesh {
    var vertices: [Float]
    var indices: [UInt16]

    static func cube() -> Mesh {
        let vertices: [Float] = [
            // Vorderseite
            -0.5, -0.5,  0.5,  // 0
             0.5, -0.5,  0.5,  // 1
             0.5,  0.5,  0.5,  // 2
            -0.5,  0.5,  0.5,  // 3
            // Rückseite
            -0.5, -0.5, -0.5,  // 4
             0.5, -0.5, -0.5,  // 5
             0.5,  0.5, -0.5,  // 6
            -0.5,  0.5, -0.5,  // 7
        ]

        let indices: [UInt16] = [
            // Vorderseite
            0, 1, 2,
            2, 3, 0,
            // Rückseite
            5, 4, 7,
            7, 6, 5,
            // Oben
            3, 2, 6,
            6, 7, 3,
            // Unten
            4, 5, 1,
            1, 0, 4,
            // Rechts
            1, 5, 6,
            6, 2, 1,
            // Links
            4, 0, 3,
            3, 7, 4,
        ]

        return Mesh(vertices: vertices, indices: indices)
    }
}

