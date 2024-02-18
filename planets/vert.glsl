// vert file and comments from adam ferriss
// https://github.com/aferriss/p5jsShaderExamples

attribute vec3 aPosition;
attribute vec2 aTexCoord;


void main(){
    vTexCoord=aTexCoord;
    vec4 position=vec4(aPosition,1.);
    vPos = position.xyz;
    float alt = altitude(position.xyz);

    position.xyz = position.xyz * (1. + 0.1 * max(alt, water_level));

    gl_Position=uProjectionMatrix*uModelViewMatrix*position;
}