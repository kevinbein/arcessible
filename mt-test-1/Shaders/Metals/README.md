#  Shadertoy

I am using [Shadertoy](https://shadertoy.com) as a testing tool to quickly develop and test shaders. Shadertoy does have a different syntax than the [Metal Shading Language (MSL)] but it is very, very similar. Therefore it is very easy to convert HLSL to MSL. 

## Shadertoy template (HLSL)

```
void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    // Standard
    vec2 uv = fragCoord / iResolution.xy;
    // Normalized pixel coordinates (from 0 to 1)
    //vec2 uv = (fragCoord - .5 / iResolution.xy) / iResolution.y;

    // "Background image" if not buffer is used
    vec4 backgroundColor = vec4(uv.xy, 0.0 ,1.0);
    
    fragColor = backgroundColor;
    vec4 col = vec4(1.0);
    
    
 // === CUSTOM CODE START ===
 
    // Example Macular Degenration:
    float d = length(uv - .5);
    d = smoothstep(.1, .5, d);
    col = vec4(vec3(d), 1.0);
     
 // === CUSTOM CODE END ===
    
    
    // Place upon image
    col = min(fragColor, col);

    // Output to screen
    fragColor = col;
}
```

## MSL template

```
#include <metal_stdlib>
using namespace metal;

// Metal Shadertoy types
#define vec2 float2
#define vec3 float3
#define vec4 float4

// Default kernel method
kernel void name_kernel(
    texture2d<float, access::read> sourceTexture [[texture(0)]],
    texture2d<float, access::write> targetTexture [[texture(1)]],
    uint2 gridPosition [[thread_position_in_grid]]
) {
    // Metal to Shadertoy naming conversion
    vec4 fragColor = sourceTexture.read(gridPosition);
    vec2 fragCoord = float2(gridPosition);
    vec2 iResolution = float2(sourceTexture.get_width(), sourceTexture.get_height());
    
    // Default Shadertoy setup
    // No coordinate aligning
    vec2 uv = fragCoord / iResolution.xy;
    // Normalized pixel coordinates (from 0 to 1)
    //vec2 uv = (fragCoord - .5 / iResolution.xy) / iResolution.y;
 
    
// === CUSTOM CODE START ===
    
    // Big, black, faded dot
    float d = length(uv - .5);
    d = smoothstep(.1, .5, d);
    vec4 col = vec4(vec3(d), 1.0);

 // === CUSTOM CODE END ===
    
    
    // Place upon image
    col = min(fragColor, col);
    
    // Output to screen
    fragColor = col;
    
    // Needed for metal
    targetTexture.write(fragColor, gridPosition);
}
```
