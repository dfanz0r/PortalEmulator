// File: simple.vert.hlsl

// This struct defines the layout of the data coming from the vertex buffer.
// The semantics (TEXCOORD0, TEXCOORD1) must match the locations set in AddVertexAttribute.
struct VSInput
{
    float3 Position : TEXCOORD0; // Corresponds to location = 0
    float4 Color    : TEXCOORD1; // Corresponds to location = 1
    
    // Instance Data (Model Matrix)
    float4 Model0 : TEXCOORD2;
    float4 Model1 : TEXCOORD3;
    float4 Model2 : TEXCOORD4;
    float4 Model3 : TEXCOORD5;
};

struct VSOutput
{
    float4 Position : SV_Position;
    float4 Color    : COLOR0;
};

cbuffer Uniforms : register(b0, space1)
{
    float4x4 ViewProj;
}

VSOutput main(VSInput input)
{
    VSOutput output;

    float4 pos = float4(input.Position, 1.0);

    // Construct Model Matrix from rows/cols
    // The input data is Column-Major (from Beef Matrix4x4), so input.Model0 is the first column (Right vector).
    // The float4x4 constructor takes arguments as ROWS.
    // So 'Model' here ends up being the Transpose of the actual instance matrix.
    float4x4 Model = float4x4(input.Model0, input.Model1, input.Model2, input.Model3);

    // Calculate final position
    // Since 'Model' is Transposed, we use mul(pos, Model) which is equivalent to mul(Transpose(Model), pos)
    // if we treat pos as a row vector.
    // This effectively does: (Model_actual * pos)
    
    float4 worldPos = mul(pos, Model);
    output.Position = mul(ViewProj, worldPos);

    output.Color = input.Color;

    return output;
}