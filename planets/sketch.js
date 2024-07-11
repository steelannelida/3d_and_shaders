

let graphshader;
let terrainshader;
let atmoshader;


// TODO: refactor into 3 channels of 1 image.
let terrain_buf_x;
let terrain_buf_y;
let terrain_buf_z;
let planet_buf;


let common_glsl;
let frag_glsl;
let vert_glsl;
let terrain_glsl
let atmo_glsl;

let fov;

let TS = 128;

function preload() {
    common_glsl = loadStrings("common.glsl")
    vert_glsl = loadStrings("vert.glsl")
    frag_glsl = loadStrings("frag.glsl")
    terrain_glsl = loadStrings("terrain.glsl")
    atmo_glsl = loadStrings("atmo.glsl")
}


function setup() {
    createCanvas(1200, 800, WEBGL);
    noStroke();
    graphshader = createShader(
        join(common_glsl, "\n") + join(vert_glsl, "\n"), 
        join(common_glsl, "\n")  + join(frag_glsl, "\n"));
    terrainshader = createFilterShader(
        join(common_glsl, "\n") + join(terrain_glsl, "\n")
    )
    atmoshader = createShader(
        join(common_glsl, "\n") + join(vert_glsl, "\n"), 
        join(common_glsl, "\n")  + join(atmo_glsl, "\n")
    );
    fov = PI/4;

    terrain_buf_x = createFramebuffer({ 
        format: FLOAT,
        width: TS,
        height: TS,
        density: 1,
    });
    terrain_buf_y = createFramebuffer({ 
        format: FLOAT,
        width: TS,
        height: TS,
        density: 1,
    });
    terrain_buf_z = createFramebuffer({ 
        format: FLOAT,
        width: TS,
        height: TS,
        density: 1,
    });

    planet_buf = createFramebuffer({format: FLOAT})

    bufs = [terrain_buf_x, terrain_buf_y, terrain_buf_z];
    for (i = 0; i < 3; ++i) {
        buf = bufs[i];
        buf.begin();
        terrainshader.setUniform('shift', random() * 3000.);
        shader(terrainshader);
        plane(TS, TS);
        buf.end();
    }
}

function draw() {
    planet_buf.begin();
    background(0., 0., 0., 0.);
    perspective(fov, width / height, 0.1, 8000);
    orbitControl(1, 1, 0);
    shader(graphshader);
    graphshader.setUniform('terrX', terrain_buf_x);
    graphshader.setUniform('terrY', terrain_buf_y);
    graphshader.setUniform('terrZ', terrain_buf_z);
    graphshader.setUniform('t', millis() * 0.001);
    sphere(140, 100, 100);
    planet_buf.end();


    shader(atmoshader);
    background(0);
    perspective(fov, width / height, 0.1, 8000);
    orbitControl(1, 1, 0);
    atmoshader.setUniform('planetColor', planet_buf);
    atmoshader.setUniform('planetDepth', planet_buf.depth);
    atmoshader.setUniform('resolution', [width, height]);
    atmoshader.setUniform('t', millis() * 0.001);

    sphere(160, 100, 100);
    console.log(frameRate());
}

function mouseWheel(event) {
    fov = fov * pow(1.001, event.delta);
    fov = min(fov, PI * 0.75);
    fov = max(fov, PI / 360);
}

