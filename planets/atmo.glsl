

void main() {
    vec2 coord = gl_FragCoord.xy / resolution;
    coord /= 2.;
    coord.y = 1. - coord.y;
    vec4 c = texture2D(planetColor, coord);
    
    mat3 nm = mat3(
        uModelViewMatrix[0].xyz, 
        uModelViewMatrix[1].xyz, 
        uModelViewMatrix[2].xyz);
    vec3 view = normalize(vec3(0., 0., -1.) * (nm));
    float depth = 2. * abs(dot(view, vPos));
    float alt = length(vPos - dot(vPos, view) * view);
    if (c.a > 0.5) {
        // reflection
        float discr = pow(dot(view, vPos), 2.) - 0.49; 
        float depth = -dot(view, vPos) - sqrt(discr);
        float cost = dot(view, light());
        vec3 in_scatter = 0.5 * air_scatter * phase(mie_g, cost) * exp(-(alt - .8) * 6. ) * depth;
        vec3 reflected = c.rgb * pow(air_scatter, vec3(depth));
        gl_FragColor = vec4(c.rgb, 1.);
    } else {
        // through atmosphere
        float cost = dot(view, light());
        vec3 in_scatter = 0.5 * air_scatter * phase(mie_g, cost) * exp(-(alt - .8) * 6. ) * depth;
        gl_FragColor = vec4(in_scatter, 1.);
    }

}

