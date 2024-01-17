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

struct surface {
    vec3 center;
    float radius;
    vec3 color;
};

struct light {
    vec3 p;
    vec3 c;
};

struct ray {
    vec3 o;
    vec3 d;
};

float get_int(surface s, ray r) {
    // p = r.o + t * r.s
    // length(r.o + t * r.s - s.center)^2 == s.radius^2
    // (r.o.x - t * r.d.x - s.center.x)^2 = (r.o.x - s.center.x) ^ 2 + t^2 * r.s.x^2
    // - 2 * t * r.d.x * (r.o.x - s.center.x)
    // rel = r.o - s.center;
    // s.radius^2 == dot(rel, rel) - 2 * t * dot(r.d, rel) + t^2; // r.d^2 == 1;
    // det = dot(r.d, rel) ^ 2 - dot(rel, rel) - s.radius^2
    // t = -dot(r.d, rel) +- sqrt(det)
    vec3 rel = r.o - s.center;
    float b = dot(r.d, rel);
    float r2 = s.radius * s.radius;
    float det = b * b - dot(rel, rel) + r2;
    float t = -b - sqrt(det);
    return t;
}

float getz(surface s, vec2 ray) {
    vec2 rv = ray - s.center.xy;
    return s.center.z - sqrt(s.radius * s.radius - dot(rv, rv));
}

vec3 getnorm(surface s, vec3 pos) {
    return normalize(s.center - pos);
}

vec2 surfcoords(surface s, vec3 pos) {
    vec3 rv = s.center - pos;
    return vec2(
        atan(rv.x, rv.y),
        atan(rv.z, length(rv.xy))
    );
}

vec3 surfcolor(surface s, vec2 surfcoords) {
    return s.color * (
        0.8 + 0.2 * cos(14. * surfcoords.x) * sin(7. * surfcoords.y));
}


void mainImage( out vec4 fragColor, in vec2 fragCoord ) {
    vec2 x = 2. * (fragCoord - 0.5 * iResolution.xy) / iResolution.x;
    float t = iTime;
    surface[5] objects = surface[5](
        surface(vec3(-0.5, 0.5, 0.), 0.05, vec3(1.0, 1.0, 1.0)),
        surface(vec3(0.5, 0.5, 0.), 0.03, vec3(0.0, 0.0, 1.0)),
        surface(vec3(-0.5, -0.5, 0.), 0.1, vec3(1.0, 0.0, 0.0)),
        surface(vec3(0.5, -0.5, 0.), 0.1, vec3(0.0824, 1.0, 0.0)),
        surface(vec3(0., 0., 0.), 0.2, vec3(1., 1., 0))
    );
    for (int i = 0; i < 4; ++i) {
        float r = float(i + 2) / 5.;
        float phase = t / r;
        objects[i].center = vec3(
           r * cos(phase),
           r * sin(phase),
           0.
        );
    }


    float d = 10. + 2. * cos( 3. * t);
    light l = light(
        vec3(d * cos(t / 5.), d * sin(t / 3.), 5. * sin(t / 8.)),
        vec3(0.9725, 1.0, 0.651) * 2.
    );

    fragColor = vec4(vec3(0.), 1.);
    float z = 1000.;
    int idx = -1;
    ray r = ray(vec3(x, -100.), vec3(0., 0., 1.));
    for (int i = 0; i < 5; ++i) {
        float zc = get_int(objects[i], r);
        if (isnan(zc) || (zc < 0.)) {
            continue;
        }
        if (zc < z) {
            z = zc;
            idx = i;
        }
    }
    vec3 pos = r.o + z * r.d;
    
    if (idx >= 0) {
        surface s = objects[idx];
        vec2 sc = surfcoords(s, pos);
        sc.x += t * (2. + float(idx));
        vec3 color = surfcolor(s, sc);
        vec3 res = 0.2 * color;

        ray raytolight = ray(pos, normalize(l.p - pos));
        float obs = length(l.p - pos);
        for (int i = 0; i < 5; ++i) {
            if (i == idx) {
                continue;
            }
            float o = get_int(objects[i], raytolight);
            if (isnan(o) || o < 0.) {
                continue;
            }
            obs = min(obs, o);
        }
        if (obs >= length(l.p - pos)) {
            vec3 n = getnorm(s, pos);
            float intens = max(0., -dot(n, raytolight.d));
            res += intens * l.c * color;
            float rintens = 10. * max(0., -dot(n, raytolight.d)- 0.95);
            res += rintens * l.c;
        }
        
        fragColor = vec4(res, 1.);
    }
}	
