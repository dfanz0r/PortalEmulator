// File: simple.vert.hlsl

// This struct defines the layout of the data coming from the vertex buffer.
// The semantics (TEXCOORD0, TEXCOORD1) must match the locations set in AddVertexAttribute.
struct InstanceData
{
    float4x4 Model;
};

StructuredBuffer<InstanceData> Instances : register(t0, space0);

struct VSInput
{
    float3 Position : TEXCOORD0; // Corresponds to location = 0
    float4 Color    : TEXCOORD1; // Corresponds to location = 1
    float3 Normal   : TEXCOORD2; // Corresponds to location = 2
    uint InstanceID : SV_InstanceID;
};

struct VSOutput
{
    float4 Position : SV_Position;
    float4 Color    : COLOR0;
    float3 Normal   : TEXCOORD0;
    float3 WorldPos : TEXCOORD1;
};

cbuffer Uniforms : register(b0, space1)
{
    float4x4 ViewProj;
}

VSOutput main(VSInput input)
{
    VSOutput output;

    float4 pos = float4(input.Position, 1.0);

    // Retrieve Model Matrix from StructuredBuffer
    float4x4 Model = Instances[input.InstanceID].Model;

    // Since Model is transposed (Beef Matrix4x4 is Column-Major), we use mul(pos, Model)
    float4 worldPos = mul(Model, pos);
    output.Position = mul(ViewProj, worldPos);
    output.WorldPos = worldPos.xyz;

    output.Normal = normalize(mul(input.Normal, (float3x3)Model));
    output.Color = input.Color;

    return output;
}