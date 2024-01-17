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

float rand(vec2 x) {
    return fract(sin(dot(x.xy,
                         vec2(1.9898,78.233)))*
        43758.5453123);
    }

float noise(vec2 x) {
    vec2 i = trunc(x);
    vec2 f = fract(x);
    f = f*f*(3.0-2.0*f);
    float a = rand(i);
    float b = rand(i + vec2(1., 0.));
    float c = rand(i + vec2(0., 1.));
    float d = rand(i + vec2(1., 1.));
    return mix(
        mix(a, b, f.x),
        mix(c, d, f.x),
        f.y);
}

float fbm(vec2 x) {
    float res = 0.;
    float amp = 0.5;
    float freq = 1.;
    for (int i = 0; i < 10; ++i) {
        res += noise(x * freq) * amp;
        amp *= 0.5;
        freq *= 2.;
    }
    return res;
}

float fbmsh(vec2 x, float t) {
    float res = 0.;
    float amp = 0.5;
    float freq = 1.;
    vec2 v = vec2(0.3, 0.8);
    float angle = 1.57;
    mat2 rot = mat2(
        cos(angle), sin(angle),
        -sin(angle), cos(angle)
    );
    for (int i = 0; i < 7; ++i) {
        x += t * v;
        v *= rot;
        res += noise(x * freq) * amp;
        amp *= 0.5;
        freq *= 2.;
    }
    return res;
}

vec3 sky(vec2 x, float t) {
    float smoke = fbmsh(x * 3., t);
    float thresh = 0.4;
    float val = max(0., smoke - thresh) / thresh;
    vec3 skycolor = mix(vec3(0.0, 0.5216, 0.7098), vec3(0.3686, 0.8196, 1.0), x.y);
    return mix(skycolor, vec3(1.), val);
}

void mainImage( out vec4 fragColor, in vec2 fragCoord ) {
    vec2 x = fragCoord / iResolution.xy;
    
    fragColor = vec4(sky(x, iTime), 1.);
}	
