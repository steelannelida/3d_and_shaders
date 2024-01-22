// A simple 2D-boid compute shader for fishes

precision mediump float;

uniform float dt;
uniform float t;
uniform vec2 mouse;
uniform bool mousePressed;
uniform bool isInit; // true for random init
uniform int N; // Number of fishes

#define MAXFISH 256 // N <= MAXFISH

uniform sampler2D fishes; // Loopback
varying vec2 vTexCoord;

float rand(vec2 x) {
    return fract(sin(dot(x.xy,
                         vec2(11.9898,78.233)))*
        43758.5453123);
}

#define PI 3.1415926

void main() {
    // this fish index
    int myidx = int(vTexCoord.x * float(N));

    // Extract current state of this fish from buffer
    vec4 px1 = texture2D(fishes, vec2(vTexCoord.x, 0.));
    vec4 px2 = texture2D(fishes, vec2(vTexCoord.x, 1.));
    vec2 pos = px1.xy; // position (in-screen is ~ [0,1] but no hard limit)
    float orientation = px1.z; // Radians, 0 points east , counter-clockwise
    float speed = px2.x; // Velocity along orientation
    float phase = px2.y; // Phase of tail-wiggling in radians; updated based on thrust
    float curve = px2.z; // Curvature of turns for tail-bending

    if (isInit) {
        // Random init everything
        pos =  vec2(
            rand(vTexCoord + t ), 
            rand(vTexCoord  -t + vec2(10., 3.))
        );
        orientation = rand(vTexCoord * 2. + t * 0.5) * 2. * PI - PI;
        speed = 0.01 * rand(vTexCoord * 2. - t * 0.5);
        curve = 0.;
        phase = rand(vTexCoord * 2. + t * 0.5) * 2. * PI - PI;
    } else {
        vec2 dir = vec2(
            cos(orientation),
            sin(orientation)
        );
        
        const float avoidR = 0.05;  // Radius of vision for avoiding 'collisions'
        const float visR = 0.1;     // Radius of vision for aligning
        vec2 avoidvec = vec2(0.);   // Vector of avoiding the closeby fishes
        vec2 center = vec2(0.);     // Center-of-mass of nearby fishes
        vec2 flowv = vec2(0.);      // Average velocity of nearby fishes
        int numvis = 0; // Number of fishes I can see
        // Look at all the other fishes
        for (int i = 0; i < MAXFISH; ++i) {
            if (i >= N) break;
            if (i == myidx) continue; // skip myself
            
            float ox = float(i) / float(N);
            vec4 opx1 = texture2D(fishes, vec2(ox, 0.));
            vec4 opx2 = texture2D(fishes, vec2(ox, 1.));
            vec2 opos = opx1.xy;
            vec2 ov = opx2.x + vec2(cos(opx1.z), sin(opx1.z));
            vec2 rv = opos - pos;
            if (length(rv) <= avoidR) {
                avoidvec -= 0.3 * normalize(rv);
            }
            if (length(rv) > visR) {
                continue;
            }
            numvis++;
            center += opos;
            flowv += ov;
        }
        vec2 v = speed * dir;
        if (numvis > 0) { 
            center /= float(numvis);
            flowv /= float(numvis);
        } else {
            center = pos;
            flowv = v;
        }
        // Cursor attracts
        float curiosity = 0.2;
        if (mousePressed && length(mouse - pos) < 0.2) {
            // But if mouse is clicked, cursor scares the close-by fish
            curiosity = -0.5;
        }
        // Acceleration
        vec2 acc = avoidvec * 1. + (center - pos) * 0.1 + (flowv - v) * 0.1 + normalize(mouse - pos) * curiosity;
        // Longitudinal acceleration - for tail wiggling
        float thrust = dot(acc, dir);
        // Curvature of tail - based on transversal acceleration
        curve = (acc.x * dir.y - acc.y * dir.x) / dot(v, v);
        // Update position and velocity
        pos += v * dt;
        v += 2. * acc * dt;
        // Water friction
        v -= 1. * v * dt;
        orientation = atan(v.y, v.x);
        speed = length(v);
        if (speed > 2.) {
            speed = 2.;
        }
        // Update tail-wiggling phase
        phase += 150. * thrust * dt;
        phase = 2. * PI * fract(phase / 2. / PI);
    }
        
    if (vTexCoord.y < 0.5) {
        gl_FragColor = vec4(pos, orientation, 1.);
    } else {
        gl_FragColor = vec4(speed, phase, curve, 1.);
    } 
}