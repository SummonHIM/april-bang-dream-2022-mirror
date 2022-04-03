precision mediump float;

varying vec2 resultCoord0;
varying vec2 resultCoord1;

uniform sampler2D textureBack;
uniform sampler2D textureFore;
uniform sampler2D textureMask;


uniform float  alpha;
uniform vec3 colorMultiply;
uniform float  maskTransitionVague;
uniform float  maskTransitionStep;
uniform float  red;
uniform float  green;
uniform float  blue;


void main()
{
	vec4 fore = texture2D(textureFore, resultCoord1);
	vec4 mask = texture2D(textureMask, resultCoord1);
	float mask_a = 1.0;

	fore.r *= red;
	fore.g *= green;
	fore.b *= blue;
	fore.a *= mask_a * alpha;

	gl_FragColor = fore;
}

