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

uniform float  weights[8];
uniform float  width;


void main()
{
	vec4 fore = texture2D(textureFore, resultCoord1) * weights[0];
	vec4 mask = texture2D(textureMask, resultCoord1);
	float mask_a = 1.0;

	fore += texture2D(textureFore, resultCoord1 + vec2(width *  1.0, 0.0)) * weights[1];
	fore += texture2D(textureFore, resultCoord1 + vec2(width * -1.0, 0.0)) * weights[1];
	fore += texture2D(textureFore, resultCoord1 + vec2(width *  2.0, 0.0)) * weights[2];
	fore += texture2D(textureFore, resultCoord1 + vec2(width * -2.0, 0.0)) * weights[2];
	fore += texture2D(textureFore, resultCoord1 + vec2(width *  3.0, 0.0)) * weights[3];
	fore += texture2D(textureFore, resultCoord1 + vec2(width * -3.0, 0.0)) * weights[3];
	fore += texture2D(textureFore, resultCoord1 + vec2(width *  4.0, 0.0)) * weights[4];
	fore += texture2D(textureFore, resultCoord1 + vec2(width * -4.0, 0.0)) * weights[4];
	fore += texture2D(textureFore, resultCoord1 + vec2(width *  5.0, 0.0)) * weights[5];
	fore += texture2D(textureFore, resultCoord1 + vec2(width * -5.0, 0.0)) * weights[5];
	fore += texture2D(textureFore, resultCoord1 + vec2(width *  6.0, 0.0)) * weights[6];
	fore += texture2D(textureFore, resultCoord1 + vec2(width * -6.0, 0.0)) * weights[6];
	fore += texture2D(textureFore, resultCoord1 + vec2(width *  7.0, 0.0)) * weights[7];
	fore += texture2D(textureFore, resultCoord1 + vec2(width * -7.0, 0.0)) * weights[7];
	fore.a *= mask_a * alpha;

	gl_FragColor = fore;
}

