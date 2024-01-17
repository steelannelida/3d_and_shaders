// Surface wave simulation with 2D final differences

precision mediump float;

#define KS 0.0      // Hooke's coef pointwise 
#define KN 1000.    // Propagation coeff (~sqrt(c))
#define L 0.65      // Viscosity
#define kernel 1    // Kernel size of neighbourhood

uniform float dt;
uniform float t;
uniform vec2 mouse;
uniform bool mousePressed;
uniform vec2 resolution; // Buffer resolution in texels;
uniform sampler2D fluid; // Loopback buf; x=displacement, y=displacement velocity
varying vec2 vTexCoord;

float rand(vec2 x) {
    return fract(sin(dot(x.xy,
                         vec2(198.98,78.233)))*
        4378.5453123);
}

void main() {
    vec2 p = vTexCoord;
    vec2 dx = vec2(1. / resolution.x, 0.);
    vec2 dy = vec2(0., 1. / resolution.y);

    vec4 me = texture2D(fluid, p); // this point
    float neigbours = 0.; // neighbour w-mean displacement
    float total = 0.; // normalization weight
    float nv = 0.; // neighbour w-mean speed
    for (int i = -kernel; i <= kernel; ++i) {
        for (int j = -kernel; j <= kernel; ++j) {
            if (i == 0 && j == 0) {
                continue;
            }
            vec2 pn = p + float(i) * dx + float(j) * dy; 
            float dist = pow(float(i * i + j * j), -0.5); //distance-based weight
            neigbours += texture2D(fluid, pn).x * dist;
            nv += texture2D(fluid, pn).y * dist;
            total += dist;
        }
    }
    neigbours /= total;
    nv /= total;

    // Self-oscillation
    float pull = -me.x * KS;
    // Wave propagation from neighbours
    pull += (neigbours - me.x) * KN;
    // Viscosity with neighbours
    pull += L * (nv - me.y);
    vec4 res;
    res.w = 1.;
    // Update displacement and velocity
    res.y = me.y + pull * dt;
    res.x = me.x + (me.y + res.y) / 2. * dt;
    // When mouse is pressed, add a small "fountain" at neighbouring pixels
    if (mousePressed && length(p - mouse) < 1. / resolution.x) {
        vec2 r = p - mouse;
        res.y += 0.003 * exp(-dot(r, r) * 100.);
    }
    // Add a little noise (a-la wind)
    res.y += 0.2 * (rand(p + t) - 0.5) * dt;
    res.z = pull;
    gl_FragColor = res;
}