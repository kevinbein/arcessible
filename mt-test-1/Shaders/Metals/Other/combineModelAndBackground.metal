//
//  addModelToBackground.metal
//  mt-test-1
//
//  Created by Kevin Bein on 20.10.22.
//

#include <metal_stdlib>
using namespace metal;

#include "../Utils/types.h"
#include "../Utils/color.h"

// https://developer.apple.com/documentation/arkit/displaying_an_ar_experience_with_metal
// https://github.com/Stinkstudios/arkit-web/blob/87b9dbafc3c1afc02d2483cd83c4a0fe04294324/ARKitWeb/Renderer.swift
kernel void combineModelAndBackground_kernel(
    texture2d<float, access::read> backgroundTexture [[texture(0)]],
    texture2d<float, access::read> modelTexture [[texture(1)]],
    //texture3d<float, access::read> noiseTexture [[texture(2)]],
    texture2d<float, access::write> targetTexture [[texture(2)]],
    uint2 gridPosition [[thread_position_in_grid]]
    //constant float &noiseIntensity [[buffer(0)]]
) {
    vec4 background = backgroundTexture.read(gridPosition);
    vec4 model = modelTexture.read(gridPosition);
    //vec4 noise = noiseTexture.read(uint3(gridPosition, 0.0));
    
    // Correct background
    //background = ycbcrToRGBTransform * background;
    
    // Alpha Blending
    vec4 fragColor = vec4((model.a * model.rgb) + ((1 - model.a) * background.rgb), 1.0);
    
    // fragColor = fragColor * noise;
    //fragColor = mix(fragColor, noise, noiseIntensity);
    
    targetTexture.write(vec4(fragColor.rgb, 1.0), gridPosition);
}
