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


void main()
{
	vec4 fore = texture2D(textureFore, resultCoord1);
	fore.a *= alpha;

	gl_FragColor = fore;
}

