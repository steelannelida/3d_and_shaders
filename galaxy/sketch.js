// bodies in the pond
// A WebGL simulation using compute shaders



let graphshader;
let fluidshader;
let galaxyshader;
let fluid;
let bodies;
let fish_img;
let fish_buf;
let fish_layer;

let W;
let H;
// Number of bodies
// BUG: bodies stop rendering if there's 48 or more.
let NB = 256;
let bottom;


function preload() {
    graphshader = loadShader('vert.glsl', 'frag.glsl');
    galaxyshader = loadShader('vert.glsl', 'galaxy.glsl');
}


function setup() {
    createCanvas(windowWidth, windowHeight, WEBGL);
    noStroke();

    // Buffer for fish states;
    // Row 0 rgb is (position x, y, orientation[rad])
    // Row 2 rgb is (speed, tail-waving phase[rad], curvature)
    // Curvature is used for fish rendering at turns.
    // See boids.glsl for updates.
    bodies = createFramebuffer({
        format: FLOAT,
        width: NB,
        height: 4,
        density: 1,
        textureFiltering: NEAREST,
    });

    // Buffer for rendering bodies in-position in the pond's frame-of-reference
    fish_layer = createFramebuffer();
}

function draw() {
    orbitControl();

    push();
    bodies.begin();
    shader(galaxyshader); // galaxy.glsl
    galaxyshader.setUniform('bodies', bodies.color);
    galaxyshader.setUniform('t', millis() * 0.001);
    galaxyshader.setUniform('dt', deltaTime * 0.001);
    galaxyshader.setUniform('isInit', frameCount < 3);
    galaxyshader.setUniform('N', NB);
    plane();
    bodies.end();
    pop();

    push();
    shader(graphshader); // galaxy.glsl
    graphshader.setUniform('bodies', bodies.color);
    graphshader.setUniform('time', millis() * 0.001);
    graphshader.setUniform('resolution', [width, height]);
    graphshader.setUniform('NB', NB)
    plane();
    pop();
   
}

