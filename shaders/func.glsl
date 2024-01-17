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
    vec2 xy = fragCoord / iResolution.xy * 2. - 1.;
    float x = xy.x;
    float t = iTime;

    float f = 0.3 * sin(x * 5. - 2. * t);
    
    float y = xy.y;
    float width = 10. / iResolution.y; 
    vec3 c = vec3(0.2157, 1.0, 0.1137) * (width - abs(y - f)) / width;
    fragColor = vec4(c, 1.);
}	
