//--------------------------------------
// èÊéZçáê¨
//--------------------------------------
texture textureBack;
texture textureFore;
texture textureMask;
texture textureUser;

sampler samplerBack = sampler_state { texture = <textureBack>; MinFilter = LINEAR; MagFilter = LINEAR; AddressU = Clamp; AddressV = Clamp; };
sampler samplerFore = sampler_state { texture = <textureFore>; MinFilter = LINEAR; MagFilter = LINEAR; AddressU = Clamp; AddressV = Clamp; };
sampler samplerMask = sampler_state { texture = <textureMask>; MinFilter = LINEAR; MagFilter = LINEAR; AddressU = Clamp; AddressV = Clamp; };
sampler samplerUser = sampler_state { texture = <textureUser>; MinFilter = LINEAR; MagFilter = LINEAR; AddressU = Clamp; AddressV = Clamp; };

float  alpha;
float3 colorMultiply;
float  maskTransitionVague;
float  maskTransitionStep;
float  param;

void vs(float4 position : POSITION, float2 texCoord0 : TEXCOORD0, float2 texCoord1 : TEXCOORD1, out float4 resultPosition : POSITION, out float2 resultTexCoord0 : TEXCOORD0, out float2 resultTexCoord1 : TEXCOORD1)
{
	resultPosition  = position;
	resultTexCoord0 = texCoord0;
	resultTexCoord1 = texCoord1;
}

void ps(float2 texCoord0 : TEXCOORD0, float2 texCoord1 : TEXCOORD1, out float4 result : COLOR0)
{
//	float4 back = tex2D(samplerBack, texCoord0);
	float4 fore = tex2D(samplerFore, texCoord1);
	float4 user = tex2D(samplerUser, texCoord1);
	float4 mask = tex2D(samplerMask, texCoord1);
	float mask_a = mask.a;
	float fore_a = fore.a * (1.0 - user.a) + user.a;

	fore.rgb *= (fore.rgb * fore.a * (1.0 - user.a) + user.rgb * user.a) / fore_a + (1.0 - param);
	fore.a   *= mask_a * alpha;

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
