//
//  daltonize.metal
//  mt-test-1
//
//  Created by Kevin Bein on 12.11.22.
//

#include <metal_stdlib>
using namespace metal;

#include "../Utils/types.h"

/*
// cb_matrices = {
//     "d": np.array([[1, 0, 0], [1.10104433,  0, -0.00901975], [0, 0, 1]], dtype=np.float16),
//     "p": np.array([[0, 0.90822864, 0.008192], [0, 1, 0], [0, 0, 1]], dtype=np.float16),
//     "t": np.array([[1, 0, 0], [0, 1, 0], [-0.15773032,  1.19465634, 0]], dtype=np.float16),
// }
constant mat3 cb_matrix_d = { {1, 0, 0}, {1.10104433,  0, -0.00901975}, {0, 0, 1} };

constant mat3 rgb2lms = {
    {0.3904725 , 0.54990437, 0.00890159},
    {0.07092586, 0.96310739, 0.00135809},
    {0.02314268, 0.12801221, 0.93605194}
};

// Precomputed inverse
constant mat3 lms2rgb = {
    {2.85831110e+00, -1.62870796e+00, -2.48186967e-02},
    {-2.10434776e-01,  1.15841493e+00,  3.20463334e-04},
    {-4.18895045e-02, -1.18154333e-01,  1.06888657e+00}
};



kernel void daltonization_kernel(
    texture2d<float, access::read> sourceTexture [[texture(0)]],
    texture2d<float, access::write> targetTexture [[texture(1)]],
    uint2 gridPosition [[thread_position_in_grid]],
    constant float &typeF [[buffer(1)]]
) {
    uint type = uint(typeF); // 0..2

    // Metal to Shadertoy naming conversion
    vec4 fragColor = sourceTexture.read(gridPosition);
    vec3 col;
                                    
# first go from RBG to LMS space
lms = transform_colorspace(rgb, rgb2lms)
# Calculate image as seen by the color blind
sim_lms = transform_colorspace(lms, cb_matrices[color_deficit])
# Transform back to RBG
sim_rgb = transform_colorspace(sim_lms, lms2rgb)
return sim_rgb

    targetTexture.write(fragColor, gridPosition);
}
*/
