//
//  colorConversion.h
//  mt-test-1
//
//  Created by Kevin Bein on 18.10.22.
//

#ifndef colorConversion_h
#define colorConversion_h

#include "types.h"

vec3 rgb2hsv(vec3 c);
vec3 hsv2rgb(vec3 c);

vec4 gammaCorrection(vec3 c);

vec4 getJetColorsFromNormalizedVal(half val);

float4 applyHSBCffect(float4 startColor, float4 hsbc);

constant mat4 ycbcrToRGBTransform = mat4(
    vec4(+1.0000f, +1.0000f, +1.0000f, +0.0000f),
    vec4(+0.0000f, -0.3441f, +1.7720f, +0.0000f),
    vec4(+1.4020f, -0.7141f, +0.0000f, +0.0000f),
    vec4(-0.7010f, +0.5291f, -0.8860f, +1.0000f)
);

#endif /* colorConversion_h */
