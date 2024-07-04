// A simple 2D-boid compute shader for bodies

precision mediump float;

uniform float dt;
uniform float t;
uniform bool isInit; // true for random init
uniform int N; // Number of bodies

#define MAXBODIES 256 // N <= MAXBODIES

uniform sampler2D bodies; // Loopback
varying vec2 vTexCoord;

float rand(vec2 x) {
    return fract(sin(dot(x.xy,
                         vec2(11.9898,78.233)))*
        43758.5453123);
}

#define PI 3.1415926

void main() {
    int myidx = int(vTexCoord.x * float(N));

    vec4 px1 = texture2D(bodies, vec2(vTexCoord.x, 0.));
    vec4 px2 = texture2D(bodies, vec2(vTexCoord.x, 0.33));
    vec4 px3 = texture2D(bodies, vec2(vTexCoord.x, 0.66));
    vec4 px4 = texture2D(bodies, vec2(vTexCoord.x, 1.));
    
    vec3 pos = px1.xyz; // position (in-screen is ~ [0,1] but no hard limit)
    vec3 v = px2.xyz;
    float m = px3.x;
    vec3 color = px4.rgb;

    if (isInit) {
        // Random init everything
        pos =  vec3(
            rand(vTexCoord  ), 
            rand(vTexCoord  + vec2(10., 3.)),
            rand(vTexCoord  - vec2(10., 3.))
        );
        pos = 0.5 + (pos - 0.5) * 0.3;
        vec3 r = pos - 0.5;
        v =  vec3(
            rand(vTexCoord  ), 
            rand(vTexCoord  + vec2(32., 73.)),
            rand(vTexCoord  + vec2(1., 113.))
        ) - 0.5;
        v += normalize(vec3(r.y, -r.x, 0.0)) / length(r) * 0.01;
        v *= 0.1;
        m = exp(3. * rand(vTexCoord  * 0.5 - vec2(-23., 45.)));
        color = pos;
    } else {
        vec3 acc = vec3(0.);
        for (int i = 0; i < MAXBODIES; ++i) {
            if (i >= N) break;
            if (i == myidx) continue; // skip myself
            
            float ox = float(i) / float(N);
            vec4 opx1 = texture2D(bodies, vec2(ox, 0.));
            vec4 opx2 = texture2D(bodies, vec2(ox, 0.33));
            vec4 opx3 = texture2D(bodies, vec2(ox, 0.66));
            vec3 opos = opx1.xyz;
            float om = opx3.x;

            vec3 d = opos - pos;
            vec3 dv = v - opx2.xyz;
            
            acc += 1e-6 * d * om * pow(length(d) + 1e-3, -3.);
        }
        pos += v * dt + acc * dt * dt / 2.;
        v += acc * dt;
    }
        
    if (vTexCoord.y < 0.25) {
        gl_FragColor = vec4(pos, 1.);
    } else if (vTexCoord.y < 0.5) {
        gl_FragColor = vec4(v, 1.);
    } else if (vTexCoord.y < 0.75) {
        gl_FragColor = vec4(m, 0., 0., 1.);
    } else {
        gl_FragColor = vec4(color, 1.);
    }
}