// File: simple.vert.hlsl

// This struct defines the layout of the data coming from the vertex buffer.
// The semantics (TEXCOORD0, TEXCOORD1) must match the locations set in AddVertexAttribute.
struct VSInput
{
    float2 Position : TEXCOORD0; // Corresponds to location = 0
    float4 Color    : TEXCOORD1; // Corresponds to location = 1
};

// This struct defines the data that will be passed from the vertex shader
// to the fragment shader. The hardware will interpolate these values across the triangle.
struct VSOutput
{
    float4 Position : SV_Position; // A required system-value semantic for the final vertex position.
    float4 Color    : COLOR0;      // Pass the vertex color to the pixel shader.
};

// The main entry point for the vertex shader.
VSOutput main(VSInput input)
{
    VSOutput output;

    // Convert the 2D input position into a 4D clip-space position.
    // The Z value of 0.0 and W value of 1.0 are standard for 2D rendering.
    output.Position = float4(input.Position, 0.0, 1.0);

    // Pass the color from the input vertex directly to the output.
    output.Color = input.Color;

    return output;
}