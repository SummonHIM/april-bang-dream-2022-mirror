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
uniform float  size;	// vsyncÇ≈ìnÇ∑íl(ÉTÉCÉY)
uniform float  ratio;	// ècâ°î‰


void main()
{
	float w = size * ratio;
	float h = size;
	vec2 uv = vec2(floor(resultCoord1.x * w) / w, floor(resultCoord1.y * h) / h);

	vec4 fore = texture2D(textureFore, uv);
	vec4 mask = texture2D(textureMask, resultCoord1);
	float mask_a = 1.0;

	fore.a *= mask_a * alpha;

	gl_FragColor = fore;
}

