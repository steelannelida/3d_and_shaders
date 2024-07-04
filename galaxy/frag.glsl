// Fishpond rendering, w. simple ray-tracing
// No lighting is done underwater except for fish shadows

precision mediump float;

varying vec2 vTexCoord;

uniform sampler2D bodies; // Prerendered fish layer with transparent background

uniform int NB;
#define MAXBODIES 256
uniform float time;

uniform mat4 uProjectionMatrix;
uniform mat4 uModelViewMatrix;
uniform vec2 resolution;

void main() {
    vec2 p = vTexCoord ;
    vec3 full_color = vec3(0.);

    for (int i = 0; i < MAXBODIES; ++i) {
        if (i >= NB) {
            break;
        }
        float x = float(i) / float(NB - 1);
        vec4 px1 = texture2D(bodies, vec2(x, 0.));
        vec4 px2 = texture2D(bodies, vec2(x, 0.33));
        vec4 px3 = texture2D(bodies, vec2(x, 0.66));
        vec4 px4 = texture2D(bodies, vec2(x, 1.));
        
        vec3 pos = px1.xyz;
        vec3 v = px2.xyz;
        float m = px3.x;
        vec3 color = px4.rgb;
        

        float d = length(p - pos.xy);
        full_color += color * exp(-d*d * 1e6 / (m * m));
    }

    gl_FragColor = vec4(full_color, 1.);
}