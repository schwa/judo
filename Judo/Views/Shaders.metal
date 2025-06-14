#include <metal_stdlib>
using namespace metal;

[[ stitchable ]]
half4 checkerboard(float2 position, half4 currentColor, float size, half4 newColor) {
    uint2 posInChecks = uint2(position.x / size, position.y / size);
    bool isColor = (posInChecks.x ^ posInChecks.y) & 1;
    return isColor ? newColor * currentColor.a : half4(0.0, 0.0, 0.0, 0.0);
}

// Time is passed in from SwiftUI as a float uniform
[[ stitchable ]]
half4 barberpole(float2 position, half4 currentColor, float stripeWidth, float time, half4 stripeColor) {
    // Move diagonally across the screen by summing x and y
    float diagonalCoord = position.x + position.y;

    // Animate by offsetting with time
    float shifted = diagonalCoord - time * 100.0;

    // Determine stripe index
    int stripeIndex = int(floor(shifted / stripeWidth));

    // Alternate stripes based on even/odd
    bool isStripe = stripeIndex % 2 == 0;

    return isStripe ? stripeColor * currentColor.a : half4(0.0);
}
