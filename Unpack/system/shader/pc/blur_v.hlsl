texture textureBack;
texture textureFore;
texture textureMask;

sampler samplerBack = sampler_state { texture = <textureBack>; MinFilter = LINEAR; MagFilter = LINEAR; AddressU = Clamp; AddressV = Clamp; };
sampler samplerFore = sampler_state { texture = <textureFore>; MinFilter = LINEAR; MagFilter = LINEAR; AddressU = Clamp; AddressV = Clamp; };
sampler samplerMask = sampler_state { texture = <textureMask>; MinFilter = LINEAR; MagFilter = LINEAR; AddressU = Clamp; AddressV = Clamp; };

float  alpha;
float3 colorMultiply;
float  maskTransitionVague;
float  maskTransitionStep;

float  weights[8];
float  height;

void vs(float4 position : POSITION, float2 texCoord0 : TEXCOORD0, float2 texCoord1 : TEXCOORD1, out float4 resultPosition : POSITION, out float2 resultTexCoord0 : TEXCOORD0, out float2 resultTexCoord1 : TEXCOORD1)
{
	resultPosition  = position;
	resultTexCoord0 = texCoord0;
	resultTexCoord1 = texCoord1;
}

void ps(float2 texCoord0 : TEXCOORD0, float2 texCoord1 : TEXCOORD1, out float4 result : COLOR0)
{
	float4 fore = tex2D(samplerFore, texCoord1) * weights[0];
	float4 mask = tex2D(samplerMask, texCoord1);
	float mask_a = mask.a;

	fore += tex2D(samplerFore, texCoord1 + float2(0.0, height *  1.0)) * weights[1];
	fore += tex2D(samplerFore, texCoord1 + float2(0.0, height * -1.0)) * weights[1];
	fore += tex2D(samplerFore, texCoord1 + float2(0.0, height *  2.0)) * weights[2];
	fore += tex2D(samplerFore, texCoord1 + float2(0.0, height * -2.0)) * weights[2];
	fore += tex2D(samplerFore, texCoord1 + float2(0.0, height *  3.0)) * weights[3];
	fore += tex2D(samplerFore, texCoord1 + float2(0.0, height * -3.0)) * weights[3];
	fore += tex2D(samplerFore, texCoord1 + float2(0.0, height *  4.0)) * weights[4];
	fore += tex2D(samplerFore, texCoord1 + float2(0.0, height * -4.0)) * weights[4];
	fore += tex2D(samplerFore, texCoord1 + float2(0.0, height *  5.0)) * weights[5];
	fore += tex2D(samplerFore, texCoord1 + float2(0.0, height * -5.0)) * weights[5];
	fore += tex2D(samplerFore, texCoord1 + float2(0.0, height *  6.0)) * weights[6];
	fore += tex2D(samplerFore, texCoord1 + float2(0.0, height * -6.0)) * weights[6];
	fore += tex2D(samplerFore, texCoord1 + float2(0.0, height *  7.0)) * weights[7];
	fore += tex2D(samplerFore, texCoord1 + float2(0.0, height * -7.0)) * weights[7];
	fore.a *= mask_a * alpha;

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
	}
}
