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
uniform float  angle;	// vsyncで渡す値(角度)
uniform float  inter;	// うねうねの間隔
uniform float  size;	// うねうねのサイズ


void main()
{
	vec2 uv = resultCoord1;
	uv.x += sin(radians(uv.y * inter - angle)) * size;

	vec4 fore = texture2D(textureFore, uv);
	vec4 mask = texture2D(textureMask, resultCoord1);
	float mask_a = 1.0;

	fore.a *= mask_a * alpha;

	gl_FragColor = fore;
}

