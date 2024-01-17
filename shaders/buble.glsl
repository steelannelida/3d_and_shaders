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

#define N 25


vec2[N] randinit(int seed) {
    vec2[N] res;
    int a = 2323127;
    int b = 3627613;
    int m = 10000;


    for (int i = 0; i < N; ++i) {
        seed = a * seed + b;
        float l1 = float(seed % 1000) / float(1000);
        seed = a * seed + b;
        float l2 = float(seed % 1000) / float(1000);
        res[i] = vec2(l1, l2);
    }
    return res;
}

float rfl(float x) {
    if (x < 0.5) {
        return 2. * x;
    }

    return 2. - 2. * x;
}

void mainImage( out vec4 fragColor, in vec2 fragCoord ) {
    vec2[N] initpts = randinit(777);
    vec2[N] vel = randinit(888);


    vec2 p = fract(fragCoord * 2. / iResolution.xy);
    p = vec2(rfl(p.x), rfl(p.y));
    float mindist = 2.;
    vec3 col = vec3(0.);
    for (int i = 0; i < N; ++i) {
        vec2 pt = fract(initpts[i] + vel[i] * iTime * 0.3);
        float d = length(p - pt);
        if (d < mindist) {
            mindist = d;
            col = vec3(initpts[i], vel[i].x);
        }
    }
    fragColor = vec4(col * (2. - 5. * mindist), 1.);
}	
