//
//  Shader.metal
//  mt-test-1
//
//  Created by Kevin Bein on 29.05.22.
//

#include <metal_stdlib>
using namespace metal;

struct VertexOut
{
    float4 position [[position]];
    float2 textureCoordinate [[user(texturecoord)]];
};

struct FragmentOut
{
    float4 position [[position]];
    float2 textureCoordinate [[user(texturecoord)]];
};
/*
vertex VertexOut inverseColor_vertex(
    texture2d<float, access::read> sourceTexture [[texture(0)]],
    //device packed_float2 *position [[buffer(0)]],
    //device packed_float2 *texturecoord [[buffer(1)]],
    uint vid [[vertex_id]]
)  {
    sourceTexture.
    SingleInputVertexIO outputVertices;
    
    outputVertices.position = float4(position[vid], 0, 1.0);
    outputVertices.textureCoordinate = texturecoord[vid];
    
    return outputVertices;
}*/

vertex float4 inverseColor_vertex(texture2d<float, access::sample> image [[texture(0)]],
                                  constant int &width [[buffer(0)]],
                                  uint vid [[vertex_id]]
) {
    uint2 pos = uint2(vid % width, vid / width);
    /*VertexOut outputVertices;
    outputVertices.position = float4(image.read(pos).xy, 0, 1);
    outputVertices.textureCoordinate = float2(pos);
    return outputVertices;*/
    
    return float4(image.read(pos).xy, 0, 1);
}

fragment float4 inverseColor_fragment(
                                      float4 fragmentInput [[stage_in]],
    texture2d<float, access::sample> targetTexture [[texture(1)]]
) {
    constexpr sampler quadSampler;
    //float4 color = targetTexture.sample(quadSampler, fragmentInput.textureCoordinate);
    float4 color = targetTexture.sample(quadSampler, fragmentInput.xy);
    
    return float4((1.0 - color.rgb), color.a);
}
