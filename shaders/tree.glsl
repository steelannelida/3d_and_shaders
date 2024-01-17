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

void mainImage( out vec4 fragColor, in vec2 fragCoord ) {
    vec2 x = (fragCoord / iResolution.xy);
    const float q = 0.5;
    const int branches = 2;
    // h = (1 - q^n) / (1 - q)
    // n = log_q(1 - (1 - q) * h)
    float h = x.y;
    int layer = int(trunc(log(1. - h) / log(q)));
    float layer_w = pow(q, float(layer));
    float layer_bottom = layer_w - 0.5;
    float layer_h = layer_w * 2.;
    int branch_num = int(trunc(x.x / layer_w)) % branches;
    vec2 branch_coord = vec2(
        fract(x.x / layer_w),
        fract(log(1. - h) / log(q))
    );
    if (branch_num % 2 == 1) {
        branch_coord.x = 1. - branch_coord.x;
    }
    // (0.5, 0) - (1., 1.)
    // dir = -0.5, 1.
    // norm = 1., 0.5
    vec2 a = vec2(0.5, 1.);
    vec2 n = vec2(1., 0.5);
    float d = dot(branch_coord - a, n) / length(n);

    //vec3 color = vec3(1.-99. * d*d * (0.5 + branch_coord.y));
    vec3 color = vec3(float(abs(d) / (1.5 - 0.5 * branch_coord.y) < 0.1));
    color.r = 0.;
    color.b = 0.;
    float t = iTime;
    fragColor = vec4(color, 1.);
}	
