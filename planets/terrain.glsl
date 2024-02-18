uniform float shift;

void main() {
  float h =  fbmsh(vTexCoord * 7., shift);
  gl_FragColor = vec4(h, 0., 0., 1.);
}