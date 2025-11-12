// File: simple.frag.hlsl

// This struct defines the data received from the vertex shader.
// The values (like Color) have been interpolated between the triangle's vertices.
struct PSInput
{
    float4 Position : SV_Position; // The pixel's screen position.
    float4 Color    : COLOR0;      // The interpolated color.
};

// The main entry point for the fragment (pixel) shader.
// The SV_Target0 semantic tells the GPU to write the output of this shader
// to the first color render target (our swapchain texture).
float4 main(PSInput input) : SV_Target0
{
    // Simply return the interpolated color for this pixel.
    return input.Color;
}