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

#define N 19
#define PI 3.1415926
#define EPS 0.001

vec4[N] randinit(int seed) {
    vec4[N] res;
    int a = 2323127;
    int b = 3627613;


    int m = 10000;

    for (int i = 0; i < N; ++i) {
        seed = a * seed + b;
        float l1 = float(seed % 1000) / float(1000);
        seed = a * seed + b;
        float l2 = float(seed % 1000) / float(1000);
        seed = a * seed + b;
        float l3 = float(seed % 1000) / float(1000);
        seed = a * seed + b;
        float l4 = float(seed % 1000) / float(1000);
        res[i] = vec4(l1, l2, l3, l4);
    }
    return res;
}

float wave(vec2 p, float t) {
    vec4[N] harmonics = randinit(131110);
    //p = quantize(p, 1. / 64.);
    float height = 0.;
    for (int i = 0; i < N; ++i) {
        vec4 h = harmonics[i];
        float wavenum = 4. * exp(2. * h.x) * pow(float(i + 1), 0.69);
        float asimuth = h.y * 2. * PI;
        vec2 wv = wavenum * vec2(cos(asimuth), sin(asimuth));
        float phase = h.z * 2. * PI;
        float amp = 1. / wavenum * exp(-h.w);
        float speed = sqrt(wavenum);
        height += exp(amp * (cos(speed * t + dot(wv, p)))) - 1.;
    }
    return 0.02 * height;
}

float lattice(vec2 pos, float width) {
	vec2 f = 1. - abs(fract(pos) - 0.5) / width;
	return max(0., max(f.x, f.y));
}

vec3 bottom(vec2 p) {
    vec3 c = mix(
        vec3(0.4, 0.5961, 0.7451),
        vec3(0.7804, 0.7333, 0.5686),
        lattice(p * 10., 0.05)
    );
	
	return  c;
}

void mainImage( out vec4 fragColor, in vec2 fragCoord ) {
    vec4[N] harmonics = randinit(131110);
    vec2 p = fract(fragCoord / iResolution.xy);
    float t = iTime;
    float h = wave(p, t);
    float dx = (wave(p + vec2(EPS, 0.), t) - h) / EPS;
    float dy = (wave(p + vec2(0., EPS), t) - h) / EPS;
    vec3 normal = normalize(vec3(-dx, -dy, 1.));
    vec3 lightvec = vec3(0., 0., -1.);
    vec3 viewvec = vec3(0., 0., -1.);
    vec3 reflected_ray = reflect(viewvec, normal);

    
    vec3 sky = vec3(0.9333, 0.9608, 0.9804); 
    vec3 reflected = sky * 9.* clamp(reflected_ray.x - 0.1, 0., 1.);

    vec3 rv = refract(viewvec, normal, 1.03);
    vec3 pt = vec3(p.xy, h);
    float depth = 5.;
    // rv * l = (-depth-pt)/rv;
    float l = -depth - pt.z / rv.z;
    vec3 bottom_pt = pt + l * rv;
    vec3 refracted = bottom(bottom_pt.xy);
    fragColor = vec4(refracted +  clamp(reflected, 0., 1.), 1.);
}	

