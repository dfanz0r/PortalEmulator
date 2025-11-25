// File: simple.frag.hlsl

struct PSInput
{
    float4 Position : SV_Position;
    float4 Color    : COLOR0;
    float3 Normal   : TEXCOORD0;
    float3 WorldPos : TEXCOORD1;
};

struct LightData
{
    float4 PositionAndType; // xyz = Position, w = Type
    float4 ColorAndIntensity; // xyz = Color, w = Intensity
    float4 DirectionAndRange; // xyz = Direction, w = Range
};

StructuredBuffer<LightData> Lights : register(t0, space2);

cbuffer SceneUniforms : register(b0, space3)
{
    float3 CameraPos;
    uint LightCount;
    float4 AmbientColor;
}

cbuffer MaterialUniforms : register(b1, space3)
{
    float3 MatAlbedo;
    float MatMetallic;
    float MatRoughness;
    float3 MatEmissive;
}

static const float PI = 3.14159265359;
static const float FLT_MIN = 1.175494351e-38;

float F_Schlick(float f0, float f90, float u)
{
    return f0 + (f90 - f0) * pow(1.0 - u, 5.0);
}

float3 F_Schlick(float3 f0, float3 f90, float u)
{
    return f0 + (f90 - f0) * pow(1.0 - u, 5.0);
}

float3 EvalDisneyDiffuse(float3 albedo, float roughness, float NoL, float NoV, float LoH)
{
    float FD90 = 0.5 + 2.0 * roughness * roughness * LoH * LoH;
    float a = F_Schlick(1.0, FD90, NoL);
    float b = F_Schlick(1.0, FD90, NoV);

    return (albedo / PI) * a * b;
}

float D_GGX(float n_dot_h, float alpha2)
{
    float f = (n_dot_h * alpha2 - n_dot_h) * n_dot_h + 1.0f;
    return alpha2 / (PI * f * f + FLT_MIN);
}

float V_SmithGGX(float n_dot_v, float n_dot_l, float alpha2)
{
    // Height-Correlated Smith Visibility Term
    float lambdaV = n_dot_l * sqrt(n_dot_v * (n_dot_v - n_dot_v * alpha2) + alpha2);
    float lambdaL = n_dot_v * sqrt(n_dot_l * (n_dot_l - n_dot_l * alpha2) + alpha2);

    return 0.5 / max(lambdaV + lambdaL, 1e-5);
}

float3 FresnelSchlick(float cosTheta, float3 F0)
{
    return F0 + (1.0 - F0) * pow(clamp(1.0 - cosTheta, 0.0, 1.0), 5.0);
}

float3 CalculateLight(LightData light, float3 N, float3 V, float3 P, float3 albedo, float roughness, float metallic, float3 F0)
{
    float3 lightPos = light.PositionAndType.xyz;
    int type = (int)(light.PositionAndType.w + 0.1); // +0.1 to avoid precision issues
    float3 lightColor = light.ColorAndIntensity.rgb;
    float intensity = light.ColorAndIntensity.w;
    float3 lightDir = light.DirectionAndRange.xyz;
    float range = light.DirectionAndRange.w;

    float3 L = float3(0,0,0);
    float attenuation = 1.0;
    
    if (type == 0) // Directional
    {
        L = normalize(-lightDir);
    }
    else if (type == 1) // Point
    {
        float3 d = lightPos - P;
        float dist = length(d);
        L = normalize(d);
        // Inverse square falloff with range
        float att = max(0, 1.0 - (dist / range)); 
        attenuation = 1.0 / (dist * dist + 1.0);
        float window = pow(max(0, 1 - pow(dist / range, 4)), 2);
        attenuation *= window;
    }
    // Spot light implementation omitted for brevity unless needed
    
    float3 H = normalize(L + V);
    float NoL = max(0.0, dot(N, L));
    float NoV = max(0.0, dot(N, V));
    float LoH = max(0.0, dot(L, H));
    float NoH = max(0.0, dot(N, H));
    
    // Alpha for GGX (roughness^2)
    float alpha = roughness * roughness;
    float alpha2 = alpha * alpha;
    
    float D = D_GGX(NoH, alpha2);
    float Vis = V_SmithGGX(NoV, NoL, alpha2);
    float3 F = FresnelSchlick(max(0.0, dot(H, V)), F0);
    
    float3 kS = F;
    float3 kD = float3(1.0, 1.0, 1.0) - kS;
    kD *= 1.0 - metallic;
    
    float3 diffuse = EvalDisneyDiffuse(albedo, roughness, NoL, NoV, LoH);
    float3 specular = D * Vis * F;
    
    return (kD * diffuse + specular) * lightColor * intensity * attenuation * NoL;
}

float4 main(PSInput input) : SV_Target0
{
    float3 N = normalize(input.Normal);
    float3 V = normalize(CameraPos - input.WorldPos);
    
    float roughness = MatRoughness;
    float3 albedo = input.Color.rgb * MatAlbedo;
    float metallic = MatMetallic;
    
    // Calculate F0
    float3 F0 = float3(0.04, 0.04, 0.04); 
    F0 = lerp(F0, albedo, metallic);
    
    float3 Lo = float3(0,0,0);
    
    for (uint i = 0; i < LightCount; i++)
    {
        Lo += CalculateLight(Lights[i], N, V, input.WorldPos, albedo, roughness, metallic, F0);
    }
    
    // Ambient
    float3 ambient = albedo * AmbientColor.rgb;
    float3 finalColor = ambient + Lo + MatEmissive;
    
    return float4(finalColor, input.Color.a);
}