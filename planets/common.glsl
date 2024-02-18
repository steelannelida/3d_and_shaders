precision mediump float;

#define rock_color vec3(0.5373, 0.3647, 0.0392)
#define water_color vec3(0.2667, 0.2392, 0.9)
#define ice_color vec3(0.8157, 0.898, 0.9922)
#define grass_color vec3(0.2941, 0.7725, 0.1059)
#define forest_color vec3(0.0431, 0.4824, 0.0745)
#define air_scatter vec3(0.0353, 0.2431, 0.4039)

#define water_level 0.4
#define temp_max 60.
#define temp_la 60.
#define temp_al 200.

#define grass_max_incl 0.3
#define grass_min_temp 15.
#define grass_max_temp 60.

#define forest_max_incl 0.8
#define forest_min_temp 0.
#define forest_max_temp 30.
#define tree_size 0.01


uniform mat4 uProjectionMatrix;
uniform mat4 uModelViewMatrix;
uniform mat3 uNormalMatrix;
uniform vec2 resolution;

uniform float t;

uniform sampler2D terrX;
uniform sampler2D terrY;
uniform sampler2D terrZ;

uniform sampler2D planetColor;
uniform sampler2D planetDepth;

varying vec2 vTexCoord;
varying vec3 vPos;


float rand(vec2 x) {
    return fract(sin(dot(x.xy,
                         vec2(1.9898,78.233)))*
        43758.5453123);
}

vec3 randvec(vec3 p) {
    mat3 m = mat3(
        3213., 453.4, 84761.,
        43., 4., 748374.,
        826549., 612345., 4782.
    );
    return fract(123. * sin (p.xyz * m));
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

vec3 light() {
    return vec3(sin(t / 10.), 0., cos(t / 10.));
}

float fbmsh(vec2 x, float t) {
    float res = 0.;
    float amp = 0.5;
    float freq = 1.;
    vec2 v = vec2(0.3, 0.8);
    float angle = 0.3;
    mat2 rot = mat2(
        cos(angle), sin(angle),
        -sin(angle), cos(angle)
    );
    for (int i = 0; i < 15; ++i) {
        x += t * v;
        v *= rot;
        res += noise(x * freq) * amp * (0.5 + res);
        amp *= 0.5;
        freq *= 2.;
    }
    return res;
}

#define SC 56.23451234

float altitude(vec3 p) {
    p = normalize(p);
    vec3 tc = p / 2. + 0.5;
    float n1 = texture2D(terrZ, tc.xy).x + texture2D(terrX, fract(tc.xy * SC)).x / SC;
    float n2 = texture2D(terrY, tc.xz).x + texture2D(terrZ, fract(tc.xz * SC)).x / SC;
    float n3 = texture2D(terrX, tc.yz).x + texture2D(terrY, fract(tc.yz * SC)).x / SC;

    vec3 n = vec3(n3, n2, n1) * p * p;
    return 2.5 * pow(n.x + n.y + n.z, 1.5) ;
}

float temperature(vec3 p) {
    float alt = altitude(p);
    float lat_sin = p.y / length(p);
    float temp_sl = temp_max - temp_la * lat_sin * lat_sin;
    return temp_sl - temp_al * max(0., alt - water_level);
}

float terrain_sdf(vec3 p) {
    float alt = altitude(p);
    float r = 1. + 0.1 * max(alt, water_level);
    return length(p) - r;
}


vec3 terrain_normal(vec3 p, float eps) {
    vec3 dx = vec3(eps, 0., 0.);
    vec3 dy = vec3(0., eps, 0.);
    vec3 dz = vec3(0., 0., eps);

    return normalize(vec3(
        (terrain_sdf(p + dx) - terrain_sdf(p - dx)) / (2. * eps),
        (terrain_sdf(p + dy) - terrain_sdf(p - dy)) / (2. * eps),
        (terrain_sdf(p + dz) - terrain_sdf(p - dz)) / (2. * eps)
    ));
}

mat3 transpose(mat3 m) {
    return mat3(
        m[0][0], m[1][0], m[2][0],
        m[0][1], m[1][1], m[2][1],
        m[0][2], m[1][2], m[2][2]
    );
}

float waveform(float x) {
    float amp = 1.;
    float s = 0.;
    for (int i = 0; i < 3; ++i) {    
        float ip = floor(x);
        s += amp * mix(rand(vec2(ip, 0.)), rand(vec2(ip + 1., 0.)), fract(x));
        x = 2. * x + 0.7; 
        amp *= 0.5;
    }
    return s;
}


float waves(vec3 p) {
    p = normalize(p);
    float freq = 1.;
    vec2 k1 = vec2(35., 454.8);
    vec2 k2 = vec2(35.55, 356.4);
    vec2 k3 = vec2(65., 355.);
    mat2 rota = mat2(
        0.6, 0.8,
        -0.8, 0.6
    );
    vec3 sum = vec3(0.);
    float amp = 1.;
    for (int i = 0; i < 3; ++i) {
        sum += amp * vec3(
            cos(32. + dot(k1, p.xy) - freq * t),
            waveform(2.45 + dot(k2, p.zx) - freq * t),
            waveform(7. - dot(k3, p.yz) - freq * t)
        );
        amp *= 0.5;
        freq *= 2.;
        k1 = k1 * 2. * rota;
        k2 = k2 * 2. * rota;
        k3 = k3 * 2. * rota;
    }
    vec3 n = sum * p * p;
    return 2e-5 * (n.x + n.y + n.z);
}

float wave_sdf(vec3 p) {
    float l = waves(p);
    float r = 1. + l;
    return length(p) - r;
}

vec3 wave_normal(vec3 p, float eps) {
    vec3 dx = vec3(eps, 0., 0.);
    vec3 dy = vec3(0., eps, 0.);
    vec3 dz = vec3(0., 0., eps);

    return normalize(vec3(
        (wave_sdf(p + dx) - wave_sdf(p - dx)) / (2. * eps),
        (wave_sdf(p + dy) - wave_sdf(p - dy)) / (2. * eps),
        (wave_sdf(p + dz) - wave_sdf(p - dz)) / (2. * eps)
    ));
}

// float tree_sdf(vec3 p) {
//     p = normalize(p);
//     vec3 trunk = floor(p / tree_size) * tree_size;
     
// }

#define ray_g 0.
#define mie_g 0.5

float phase(float g, float cost) {
    return (
        3. * (1. - g * g) /
        (2. * (2. + g * g)) * 
        (1. + cost * cost) / 
        pow(1. + g*g - 2. * g * cost, 1.5)
    );
}