//
//  daltonization.metal
//  mt-test-1
//
//  Created by Kevin Bein on 04.10.22.
//

#include <metal_stdlib>
using namespace metal;

// Metal Shadertoy types
#define vec2 float2
#define vec3 float3
#define vec4 float4
#define mat3 float3x3

constant mat3 mRGBToXYZ = {
    { 0.41242400, 0.21265600, 0.01933240 },
    { 0.35757900, 0.71515800, 0.11919300 },
    { 0.18046400, 0.07218560, 0.95044400 }
};

// Rotation matrices

// -11.4783f
constant mat3 rotProt_x = { {1., -0., 0.}, {0., 0.98000014, 0.19899679}, {-0., -0.19899679, 0.98000014} };
constant mat3 rotProt_y = { { 0.98000014, -0.,-0.19899679}, { 0., 1., -0.}, { 0.19899679, 0., 0.98000014} };
constant mat3 rotProt_z = { { 0.98000014, 0.19899679, 0. }, { -0.19899679, 0.98000014, -0. }, {-0. ,0. ,1. } };
// -8.10959f
constant mat3 rotDeut_x = { {1., -0., 0.}, {0., 0.99000006, 0.14106694}, {-0., -0.14106694, 0.99000006} };
constant mat3 rotDeut_y = { { 0.99000006, -0., -0.14106694}, { 0., 1., -0.}, { 0.14106694, 0., 0.99000006} };
constant mat3 rotDeut_z = {{ 0.99000006, 0.14106694, 0. }, { -0.14106694, 0.99000006, -0. }, { -0., 0., 1. } };
// +46.37f
constant mat3 rotTrit_x = { {1., 0., 0.}, {0., 0.68999862, -0.72381068}, {0., 0.72381068, 0.68999862} };
constant mat3 rotTrit_y = { { 0.68999862, 0., 0.72381068}, { 0., 1., 0.,}, { -0.72381068, 0., 0.68999862 } };
constant mat3 rotTrit_z = { { 0.68999862, -0.72381068, 0. },{ 0.72381068, 0.68999862, 0. }, { 0., 0., 1.} };

float F(const float p) {
    if (p < 0.008856)
        return p * (841.0 / 108.0) + (4.0 / 29.0);
    return pow(p, 1.0 / 3.0);
}

vec3 XYZToLab(const vec3 vector) {
    float fX = vector.x / 0.950456;
    float fY = vector.y / 1.0;
    float fZ = vector.z / 1.088754;
    fX = F(fX);
    fY = F(fY);
    fZ = F(fZ);
    return vec3(116.0 * fY - 16.0,
                500.0 * (fX - fY),
                200.0 * (fY - fZ));
}

float gammaCorrection(const float value) {
    float ret;
    if (value <= 0.018) {
        ret = value / 4.5138;
    } else {
        ret = pow(((value + 0.099) / 1.009), 1.0 / 0.45);
    }
    return ret;
}
vec3 RGBGammaCorrection(const vec3 rgbcol) {
    return vec3(gammaCorrection(rgbcol.x), gammaCorrection(rgbcol.y), gammaCorrection(rgbcol.z));
}


constexpr sampler s = sampler(coord::normalized, address::clamp_to_edge, filter::linear);

// Default kernel method
kernel void daltonizationStep0_kernel(
    texture2d<float, access::read> sourceTexture [[texture(0)]],
    texture2d<float, access::write> targetTexture [[texture(1)]],
    uint2 gridPosition [[thread_position_in_grid]],
    constant float &typeF [[buffer(1)]]
) {
    uint type = uint(typeF); // 0..2
    
    // Metal to Shadertoy naming conversion
    vec4 fragColor = sourceTexture.read(gridPosition);
    vec3 col;
    
    // ========= Custom code START =========
    
    mat3 rotMat = type == 0 ? rotProt_y : (type == 1 ? rotProt_y : rotTrit_y);
    
    // Convert picture to L*a*b* and align dichromats plane to b* axis
    // b* axis should be y in our case
    vec3 RGB = fragColor.rgb;
    vec3 mRGB = RGBGammaCorrection(RGB);
    vec3 XYZ = mRGBToXYZ * mRGB;
    vec3 Lab = XYZToLab(XYZ);
    Lab = rotMat * Lab;
    
    // texture2d<float, access::read_write> temporaryTexture1;
    // temporaryTexture1.write(vec4(Lab, 1.0), gridPosition);
    
    // Principial Component Analysis - Step 1
    
    //vec4 t = vec4(noiseTexture.read(gridPosition)); // texture2DRect(noisetex, gl_TexCoord[0].st);
    //vec4 o = vec4(Lab, 1); // texture2DRect(labtex, gl_TexCoord[0].st); // .st === .xy
    //vec4 n = vec4(temporaryTexture1.sample(s, Lab.xy)); // texture2DRect(labtex, t.xy);
    // col = PCAStep1(t, o, n);
    // PCAStep1(noiseTexture, temporaryTexture1, Lab, gridPosition);
    
    col = Lab;

    // ========= Custom code END =========
    
    // Output to screen
    fragColor = vec4(vec3(col), 1.0);
    
    targetTexture.write(fragColor, gridPosition);
    //targetTexture.write(noiseTexture.read(gridPosition), gridPosition);
}
