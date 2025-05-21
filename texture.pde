PImage dirt, grassTop, grassSide;
float rotx, roty;

void setup() {
 size(800, 800, P3D);
 dirt = loadImage("Dirt.png");
 grassTop = loadImage("GrassTop.png");
 grassSide = loadImage("GrassSide.png");

 textureMode(NORMAL);
 noStroke();
}

void draw() {
 background(0);
 pushMatrix();
 translate(width / 2, height / 2, 0);
 scale(200);
 rotateX(rotx);
 rotateY(roty);

 // TOP face - grassTop x y z vx vy
 beginShape(QUADS);
 texture(grassTop);
 vertex(0, 0, 0, 0, 0);
 vertex(1, 0, 0, 1, 0);
 vertex(1, 0, 1, 1, 1);
 vertex(0, 0, 1, 0, 1);
 endShape();

 // BOTTOM face - dirt
 beginShape(QUADS);
 texture(dirt);
 vertex(0, 1, 0, 0, 0);
 vertex(1, 1, 0, 1, 0);
 vertex(1, 1, 1, 1, 1);
 vertex(0, 1, 1, 0, 1);
 endShape();

 // FRONT face - grassSide
 beginShape(QUADS);
 texture(grassSide);
 vertex(0, 0, 1, 0, 0);
 vertex(1, 0, 1, 1, 0);
 vertex(1, 1, 1, 1, 1);
 vertex(0, 1, 1, 0, 1);
 endShape();

 // BACK face - grassSide
 beginShape(QUADS);
 texture(grassSide);
 vertex(1, 0, 0, 0, 0);
 vertex(0, 0, 0, 1, 0);
 vertex(0, 1, 0, 1, 1);
 vertex(1, 1, 0, 0, 1);
 endShape();

 // LEFT face - grassSide
 beginShape(QUADS);
 texture(grassSide);
 vertex(0, 0, 0, 0, 0);
 vertex(0, 0, 1, 1, 0);
 vertex(0, 1, 1, 1, 1);
 vertex(0, 1, 0, 0, 1);
 endShape();

 // RIGHT face - grassSide
 beginShape(QUADS);
 texture(grassSide);
 vertex(1, 0, 1, 0, 0);
 vertex(1, 0, 0, 1, 0);
 vertex(1, 1, 0, 1, 1);
 vertex(1, 1, 1, 0, 1);
 endShape();

 popMatrix();
}

void mouseDragged() {
 rotx += (pmouseY - mouseY) * 0.01;
 roty += (pmouseX - mouseX) * -0.01;
}
