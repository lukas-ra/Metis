#include <metal_stdlib>
using namespace metal;

struct VertexIn {
    float4 position [[attribute(0)]];
    float4 color [[attribute(1)]];
};

struct VertexOut {
    float4 position [[position]];
    float4 color;
};

vertex VertexOut vertex_shader(
    const VertexIn vertex_in [[stage_in]],
    constant float4x4 &modelViewProjectionMatrix [[buffer(0)]]
) {
    VertexOut vertex_out;
    vertex_out.position = modelViewProjectionMatrix * vertex_in.position;
    vertex_out.color = vertex_in.color;
    return vertex_out;
}

fragment float4 fragment_shader(VertexOut fragment_in [[stage_in]]) {
    return fragment_in.color;
}
