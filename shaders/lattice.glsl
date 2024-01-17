// uniform vec3 iResolution;
// uniform float iTime;
// uniform float iTimeDelta;
// uniform float iFrame;
// uniform float iChannelTime[4];
// uniform vec4 iMouse;
// uniform vec4 iDate;
// uniform float iSampleRate;
// uniform vec3 iChannelResolution[4];
// uniform samplerXX iChanneli;

float lattice(vec2 pos, float width) {
	vec2 f = 1. - abs(fract(pos) - 0.5) / width;
	return max(0., max(f.x, f.y));
}

void mainImage( out vec4 fragColor, in vec2 fragCoord ) {
	vec2 p = fragCoord / iResolution.xy;
	vec3 c = vec3(lattice(p * 10., 0.1)) * vec3(0.1843, 1.0, 0.0);
	c = max(c, vec3(lattice(p * 20., 0.1)) * vec3(0.9843, 0.0, 1.0));
	
	fragColor = vec4(c, 1.);
}	
