texture textureBack;
texture textureFore;
texture textureMask;

sampler samplerBack = sampler_state { texture = <textureBack>; };
sampler samplerFore = sampler_state { texture = <textureFore>; };
sampler samplerMask = sampler_state { texture = <textureMask>; };

float  alpha;
float3 colorMultiply;
float  maskTransitionVague;
float  maskTransitionStep;

void vs(float4 position : POSITION, float2 texCoord0 : TEXCOORD0, float2 texCoord1 : TEXCOORD1, out float4 resultPosition : POSITION, out float2 resultTexCoord0 : TEXCOORD0, out float2 resultTexCoord1 : TEXCOORD1)
{
	resultPosition  = position;
	resultTexCoord0 = texCoord0;
	resultTexCoord1 = texCoord1;
}

void ps(float2 texCoord0 : TEXCOORD0, float2 texCoord1 : TEXCOORD1, out float4 result : COLOR0)
{
	float4 fore = tex2D(samplerFore, texCoord1);
	fore.a *= alpha;

	result = fore;
}

technique technique0
{
	pass p0
	{
		VertexShader     = compile vs_2_0 vs();
		PixelShader      = compile ps_3_0 ps();
		CullMode         = NONE;
		ZEnable          = false;
		AlphaBlendEnable = true;
		Texture[0]       = (textureFore);
		MagFilter[0]     = LINEAR;
		MinFilter[0]     = LINEAR;
		AddressU[0]      = CLAMP;
		AddressV[0]      = CLAMP;
	}
}
