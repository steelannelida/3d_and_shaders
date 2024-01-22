// Fishpond rendering, w. simple ray-tracing
// No lighting is done underwater except for fish shadows

precision mediump float;

varying vec2 vTexCoord;

uniform sampler2D fluid; // Water level buffer
uniform sampler2D bottom; // Bottom texture
uniform sampler2D fishes; // Prerendered fish layer with transparent background


uniform vec2 fluidRes; // Resolution of water level
uniform float time;

float rand(vec2 x) {
    return fract(sin(dot(x.xy,
                         vec2(1.9898,78.233)))*
        43758.5453123);
}

float noise(vec2 x) {
    vec2 i = floor(x);
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
    for (int i = 0; i < 3; ++i) {
        x += t * v;
        v *= rot;
        res += noise(x * freq) * amp;
        amp *= 0.5;
        freq *= 2.;
    }
    return res;
}

vec3 sky(vec2 x, float t) {
    // Renders sky with clouds using Fractal Brownian Motion with moving layers
    float smoke = fbmsh(x * 3., t);
    float thresh = 0.4;
    float val = max(0., smoke - thresh) / thresh;
    // Gradient sky color
    vec3 skycolor = mix(vec3(0.0, 0.5216, 0.7098), vec3(0.3686, 0.8196, 1.0), x.y);
    return mix(skycolor, vec3(1.), val);
}

void main() {
    vec2 p = vTexCoord;

    // Camera plane always coincides with water surface
    float h = 0.1 * texture2D(fluid, p).x / 1.;
    vec2 eps = 1. / fluidRes;
    float dx =  (0.1 *texture2D(fluid, p + vec2(eps.x, 0.)).x - h) / eps.x;
    float dy = (0.1 * texture2D(fluid, p + vec2(0., eps.y)).x - h) / eps.y;
    // Normal of water surface via finite diff
    vec3 normal = normalize(vec3(-dx, -dy, 1.));
    
    vec3 camfocus = vec3(0., 1., 20.);
    vec3 pt = vec3(p.xy, 0.);
    // Even if viewed from the side. This isn't correct but looks ok.
    vec3 viewvec = normalize(pt - camfocus);
    

    // Refracted ray underwater
    vec3 rv = refract(viewvec, normal, 1.3);
    float depth = 0.5; // Bottom depth
    float fishdep = 0.25; // Depth where fishes swim 
    float l = -depth - pt.z / rv.z;
    vec3 bottom_pt = pt + l * rv; // Where the ray hits bottom
    float fl = -fishdep - pt.z / rv.z;
    vec3 fish_pt = pt + fl * rv; // Where the ray hits fishes

    vec4 fish_px = texture2D(fishes, fish_pt.xy); 
    fish_px.rgb = pow(fish_px.rgb, vec3(1.5, 2.5, 3.5));
    vec3 bottom_px = texture2D(bottom, fract(bottom_pt.xy)).rgb;
    bottom_px *= 1. - 0.7 *  texture2D(fishes, bottom_pt.xy).a; // Fish shadow (lighted from directly above)
    vec3 refracted = mix(bottom_px, fish_px.rgb, fish_px.a); // Refracted light color
    
    vec3 specv = reflect(viewvec, normal); // Reflected light
    vec2 skycoord = specv.xy / length(specv); // Where it hits the sky (at infinite height)
    vec3 sundir = normalize(vec3(-1., 0., 1.)); // Direction of the sun
    vec3 suncolor = vec3(1.0, 0.9843, 0.0588);
    vec3 reflected = 10. * sky(skycoord, time * 0.2) + max(0., dot(specv, sundir) - 0.9) * suncolor * 10.; // Sky+sun color

    float R0 = pow(0.3 / 2.3, 2.); 
    float R = R0 + (1. - R0) * pow(1. - dot(specv, normal), 5.); // Reflection coeff (Schlick's approximation)
    

    gl_FragColor = vec4((1. - R0) * refracted + R0 * reflected, 1.);
}