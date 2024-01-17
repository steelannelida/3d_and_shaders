// Fishes in the pond
// A WebGL simulation using compute shaders



let graphshader;
let fluidshader;
let boidshader;
let fluid;
let fishes;
let fish_img;
let fish_buf;
let fish_layer;

let W;
let H;
// Number of fishes
// BUG: fishes stop rendering if there's 48 or more.
let NB = 40;
let bottom;


function preload() {
    // The main shader for the whole screen
    graphshader = loadShader('vert.glsl', 'frag.glsl');
    // Compute shader for the pond's surface (waves triggered by mousedown)
    fluidshader = loadShader('vert.glsl', 'fluid.glsl');
    // Compute shader for fish behaviour (simple boids simulation)
    boidshader = loadShader('vert.glsl', 'boids.glsl');
    // Individual fish shader
    fish_shader = loadShader('vert.glsl', 'fishanim.glsl');
    // Texture for pond bottom
    bottom = loadImage('bottom.png');
    // Top-down image of a fish
    fish_img = loadImage('fishy.png');
}


function setup() {
    createCanvas(bottom.width * 0.75, bottom.height * 0.75, WEBGL);
    noStroke();

    // Buffer for the surface waves.
    // R channel for level displacement, G-channel for vertical speed.
    // See fluid.glsl for updates.
    W = bottom.width/8;
    H = bottom.height/8;
    fluid = createFramebuffer({ 
        format: FLOAT,
        width: W,
        height: H,
        density: 1,
    });

    // Buffer for fish states;
    // Row 0 rgb is (position x, y, orientation[rad])
    // Row 2 rgb is (speed, tail-waving phase[rad], curvature)
    // Curvature is used for fish rendering at turns.
    // See boids.glsl for updates.
    fishes = createFramebuffer({
        format: FLOAT,
        width: NB,
        height: 2,
        density: 1,
        textureFiltering: NEAREST,
    });

    // Animated fish buffer.
    // All fishes get rendered in 1 buffer one-above-the-other, regardless of position and orientation
    // See fishanim.glsl
    fish_buf = createFramebuffer({
        width: fish_img.width / 2,
        height: fish_img.width / 2 * NB,
        density: 1,
    })
    // Buffer for rendering fishes in-position in the pond's frame-of-reference
    fish_layer = createFramebuffer();
}

function draw() {
    // Run fluid simulation N times
    // It seems stable enough at 60. At low numbers will self-oscilate
    // TODO: use a stable integration algo, e.g. higher-order Runge-Kuta. 
    let N = 60;
    for (i = 0; i < N; ++i) {
        fluid.begin()
        shader(fluidshader); // fluid.glsl
        fluidshader.setUniform('dt', deltaTime * 0.001 / N);
        fluidshader.setUniform('t', millis() * 0.001)

        fluidshader.setUniform('resolution', [W * 1., H * 1.]);
        fluidshader.setUniform('mouse', [
            map(mouseX, 0, width, 0, 1),
            map(mouseY, 0, height,  1, 0)
        ]);
        fluidshader.setUniform('mousePressed', mouseIsPressed)
        fluidshader.setUniform('fluid', fluid.color);
        plane(W, H);    
        fluid.end();
    }
    
    // Calculate fish position and motion
    push();
    fishes.begin();
    shader(boidshader); // boids.glsl
    boidshader.setUniform('fishes', fishes.color);
    boidshader.setUniform('t', millis() * 0.001);
    boidshader.setUniform('dt', deltaTime * 0.001);
    boidshader.setUniform('isInit', frameCount < 3);
    boidshader.setUniform('N', NB);
    boidshader.setUniform('mouse', [
                map(mouseX, 0, width, 0, 1),
                map(mouseY, 0, height,  1, 0)
            ]);
    boidshader.setUniform('mousePressed', mouseIsPressed)
    plane();
    fishes.end();
    pop();

    // Animate each fish tail-wiggling
    push();
    fish_buf.begin();
    clear();
    shader(fish_shader); //fishanim.glsl
    fish_shader.setUniform('N', NB);
    fish_shader.setUniform('texture', fish_img);
    fish_shader.setUniform('fishes', fishes);
    fish_shader.setUniform('t', millis() * 0.001);
    fish_shader.setUniform('ratio', 1. * fish_img.height / fish_img.width);
    plane(width, -height)
    fish_buf.end();
    pop();

    // Load fish positions to CPU
    fishes.loadPixels();
    // Render all fishes in their positions using fish_buf as texture
    fish_layer.begin();
    clear();
    // Fish size
    let sc = 0.05;
    for (i = 0; i < NB; ++i) {
        push();
        x = (fishes.pixels[i * 4] - 0.5) * width;
        y = (fishes.pixels[i * 4 + 1] - 0.5) * height;
        angle = fishes.pixels[i * 4 + 2];
        // Transform into the fish frame of reference
        translate(x,y);
        rotateZ(angle);
        texture(fish_buf);
        textureMode(NORMAL);

        beginShape();
        w = fish_img.width * sc / 2;
        h = fish_img.width * sc / 2;
        // Draw a square for each fish and use its pard of fish_buf as texture.
        vertex(-w, -h, 0, 1. * i / NB);
        vertex(w, -h, 1, 1. * i / NB);
        vertex(w, h, 1, 1. * (i + 1) / NB);
        vertex(-w, h, 0, 1. * (i + 1) / NB);
        endShape(CLOSE);
        pop();
    }
    fish_layer.end();

    // Final render: bottom and fishes refracted by the surface.
    push();
    shader(graphshader); // frag.glsl
    graphshader.setUniform('fluid', fluid.color);
    graphshader.setUniform('fishes', fish_layer.color);
    graphshader.setUniform('bottom', bottom);
    graphshader.setUniform('fluidRes', [W * 1., H * 1.])
    graphshader.setUniform('time', millis() * 0.001)
    plane();
    pop();
   
}

