
#define EPS 1e-3

void main() {
    vec2 p = vTexCoord;
    float alt = altitude(vPos);
    vec3 norm = terrain_normal(vPos, 1e-3);
    // vec3 light = vec3(
    //     sin(t / 5.),  0.1 * cos(t / 5.), cos(t / 5.));
    vec3 light = light();
    mat3 nm = mat3(
        uModelViewMatrix[0].xyz, 
        uModelViewMatrix[1].xyz, 
        uModelViewMatrix[2].xyz);
    vec3 view = normalize(vec3(0., 0., -1.) * (nm));
    float temp = temperature(vPos);
    
    vec3 rock_c = rock_color * dot(light, norm);

    float is_ice = smoothstep(-1., 1.,  temp);
    vec3 ice_norm = terrain_normal(vPos, 3e-2);
    vec3 ice_c = ice_color * dot(light, ice_norm);
    vec3 ice_spec =normalize(randvec(vPos) - 0.5 + ice_norm);
    ice_c += ice_c * pow(max(0., 100. * (
        dot(reflect(view, ice_spec), light) - 0.99)), 5.);

    float incl = sqrt(1. - pow(dot(norm, normalize(vPos)), 2.));
    float is_grass = (1. - step(grass_max_incl, incl))
         * step(grass_min_temp, temp)
         * (1. - step(grass_max_temp, temp));
    vec3 grass_c = grass_color * dot(light, norm);
    
    float is_forest = (1. - step(forest_max_incl, incl))
         * step(forest_min_temp, temp)
         * (1. - step(forest_max_temp, temp));
    vec3 forest_c = forest_color * dot(light, norm);

    float is_water = step(water_level + 10. * waves(vPos), alt);
    vec3 water_c = pow(water_color, 0.5 + 40. * vec3(water_level - alt)) * dot(light, normalize(vPos));
    vec3 water_normal = wave_normal(vPos, 1e-3);
    water_c += pow(max(0., dot(reflect(view, water_normal), light)), 15.); 

    // float spec_cos = dot(reflect(view, normalize(vPos)), light);
    // spec_cos = max(0., spec_cos);
    // float r0 = 0.2;
    // water_c += max(0., r0 * pow(spec_cos, 15.));
    
    vec3 color = mix(
       ice_c,
        mix(
            water_c, 
            mix(mix(rock_c, forest_c, is_forest), 
                grass_c, 
                is_grass),  
            is_water
        ),
        is_ice
    );
    
    gl_FragColor = vec4(color, 1.);
}

