precision mediump float;

varying vec2 resultCoord0;
varying vec2 resultCoord1;

//--------------------------------------
// ÉXÉNÉäÅ[Éìçáê¨
//--------------------------------------
uniform sampler2D textureBack;
uniform sampler2D textureFore;
uniform sampler2D textureMask;
uniform sampler2D textureUser;


uniform float  alpha;
uniform vec3 colorMultiply;
uniform float  maskTransitionVague;
uniform float  maskTransitionStep;
uniform float  param;


void main()
{
//	uniform vec4 back = tex2D(samplerBack, texCoord0);
	vec4 fore = texture2D(textureFore, resultCoord1);
	vec4 user = texture2D(textureUser, resultCoord1);
	vec4 mask = texture2D(textureMask, resultCoord1);
	float mask_a = 1.0;

	fore.rgb  = (1.0 - ((1.0 - fore.rgb) * (1.0 - user.rgb * user.a)));
	fore.a   *= mask_a * alpha;

	gl_FragColor = fore;
}

