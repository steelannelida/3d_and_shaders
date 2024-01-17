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


const vec3[7] colors = vec3[7](
    vec3(0., 0., 0.),
    vec3(0.0, 0.9843, 0.1961),
    vec3(0.9686, 0.0, 1.0),
    vec3(1.0, 1.0, 0.0),
    vec3(0.251, 1.0, 0.0),
    vec3(1.0, 0.6157, 0.0),
    vec3(0.0, 0.2824, 1.0)
);


vec3 fracSquare(vec2 pos, int iters) {
    float D = 3.;
    vec3 res = vec3(1., 1., 1.);
    for (int i = 0; i < iters; ++i) {
        vec2 sector = trunc(pos * D);
        if (sector == vec2(1., 1.)) {
            res =colors[iters - i - 1];
        }
    
        pos = fract(pos * D);
    }
    return res;
}

void mainImage( out vec4 fragColor, in vec2 fragCoord ) {
    float t = 1. - fract(iTime / 2.);
    vec2 pos = fract(fragCoord  / (iResolution.x * (exp(t * log(3.)))));
    float a = 3.1415926 * t / 2.;
    float y = pos.y;
    mat2 rot = mat2(
        cos(a), sin(a),
        -sin(a), cos(a)
    );
    pos = pos * rot;
    //pos = vec2(pos.x + 0.1 * sin(y * 2. * 3.1415 +  2. * t * 3.1415926), pos.y);
    vec3 col1 = fracSquare(pos, 5);
    vec3 col2 = fracSquare(pos, 6);
    vec3 col = mix(col1, col2, t);
	fragColor = vec4(vec3(col), 1.);
}	
