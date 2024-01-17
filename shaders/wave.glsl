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

#define N 43

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

float rfl(float x) {
    if (x < 0.5) {
        return 2. * x;
    }
    return 2. - 2. * x;
}
const float pi = 3.1415926;

float quantize(float x, float size) {
    return trunc(x / size) * size;
}

vec3 quantize(vec3 x, float size) {
    return vec3(
        quantize(x.x, size),
        quantize(x.y, size),
        quantize(x.z, size)
    );
}
vec2 quantize(vec2 x, float size) {
    return vec2(
        quantize(x.x, size),
        quantize(x.y, size)/*  */
    );
}



void mainImage( out vec4 fragColor, in vec2 fragCoord ) {
    vec4[N] harmonics = randinit(131110);
    vec4[N] colors = randinit(888);
    vec2 p = fract(2.5 * fragCoord / iResolution.xy);
    //p = quantize(p, 1. / 64.);
    vec3 c = vec3(0.);
    float t = iTime;
    for (int i = 0; i < N; ++i) {
        vec4 h = harmonics[i];
        h.xy = trunc(h.xy * 2.) * 2. * pi;
        vec3 part = h.w * colors[i].xyz * sin(h.x * p.x + h.y * p.y + h.z * t / 1.);
        //part =  quantize(part, 0.02);
        c += part;
    }
    //c = quantize(c, 0.1);
    fragColor = vec4(mix(c, fract(c), 0.5 + 0.5 * sin(t)), 1.);
}	

