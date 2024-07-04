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

#define MAXITER 1024

vec2 cplx_mul(vec2 a, vec2 b) {
    return vec2(a.x * b.x - a.y * b.y, a.x * b.y + b.x * a.y);
}

vec3 hsb2rgb(vec3 c ){
    vec3 rgb = clamp(abs(mod(c.x*6.0+vec3(0.0,4.0,2.0),
                             6.0)-3.0)-1.0,
                     0.0,
                     1.0 );
    rgb = rgb*rgb*(3.0-2.0*rgb);
    return c.z * mix(vec3(1.0), rgb, c.y);
}

vec3 mandelbrot(vec2 c, int iter) {
    iter = min(iter, MAXITER);
    vec2 z = vec2(0.);
    int i = 0;
    float d = 1e8;
    for (i = 0; i < MAXITER; ++i) {
        if (i >= iter) {
            break;
        }
        z = cplx_mul(z, z) + c;
        // if (length(z) >= 1e3) {
        //     return vec3(0.);
        // }
        d = min(length(z - vec2(1., 0.)), d);
    }
    float h = d;
    return hsb2rgb(vec3(h, h, h) * float(iter) / 4.);
}

void mainImage( out vec4 fragColor, in vec2 fragCoord ) {
    float t = iTime;
    t *= 2.;
    vec2 c = fragCoord / iResolution.xy;
    c -= 0.5;
    c *= 2.;
    c *= 4.;
    c *= exp(-t / 10.);
    c += vec2(-1.416, 0.);

    vec3 z0 = mandelbrot(c, int(floor(t)));
    vec3 z1 = mandelbrot(c, int(ceil(t)));
    fragColor = vec4( mix(z0, z1, fract(t)),  1.);
}	
