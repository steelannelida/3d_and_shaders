// Fish animation shader. Animates all the fishes in one buffer
// Fishes are stuck vertically and rendered as squares

precision mediump float;

varying vec2 vTexCoord;

// Still image of 1 fish, with transparent background, horizontal, headed right
uniform sampler2D texture;
// All fish states from boids.glsl
uniform sampler2D fishes;
// Number of fishes
uniform int N;
uniform float t;
// ratio of fish texture width to length
uniform float ratio;

void main() {
    vec2 p = vTexCoord;
    float fishidx = floor(p.y * float(N));
    p.y = fract(p.y * float(N));

    float phase = texture2D(fishes, vec2(fishidx / float(N), 1.)).y;
    float curve = texture2D(fishes, vec2(fishidx / float(N), 1.)).z;
    // Adjust aspec ratio
    p.y = 0.5 + (p.y - 0.5) / ratio;
    // Wiggle tail,
    p.y += 0.3  * (1. - p.x)  * sin(phase + 3. * p.x);
    // Bend tail at turns
    p.y += pow(p.x - 0.9, 4.) * 0.4 * curve;

    vec4 pixel = texture2D(texture, p);
    if (p.y < 0.1 || p.y > 0.9) {
         pixel = vec4(0.);
    }
    // Palet swaps for some fishes
    if (fishidx < 5.) {
        pixel.rg = pixel.gr;
    } else  if (fishidx < 10.) {
        pixel.rgb = pixel.grr;
    } else  if (fishidx < 15.) {
        pixel.rg = pixel.rr;
    }
    gl_FragColor = vec4(pixel.rgb * pow(sin(p.y * 3.1415), 3.), pixel.a);
}