import java.awt.Robot;

PImage mapImg, grass, birch, glass, logSide, logTop, doorTop, doorBottom;
Robot rbt;

boolean wkey, akey, skey, dkey, spaceKey, shiftKey;
float eyeX, eyeY, eyeZ, focusX, focusY, focusZ;
float upX = 0, upY = 1, upZ = 0;
float lrA, udA;
final float gridSize = 100;
int mapW = 25, mapH = 25;
float sunAngle = 0, speed = 8;

void setup() {
  size(1200, 800, P3D);
  textureMode(NORMAL);
  
  // Create 25x25 map (white=grass, black=glass)
  mapImg = createImage(mapW, mapH, RGB);
  mapImg.loadPixels();
  for (int i = 0; i < mapImg.pixels.length; i++) {
    int x = i % mapW;
    int y = i / mapW;
    mapImg.pixels[i] = (x % 4 == 0 && y % 4 == 0) ? color(0) : color(255);
  }
  mapImg.updatePixels();

  // Load textures
  grass = loadImage("grass.jpg");
  birch = loadImage("birch.jpg");
  glass = loadImage("glass.jpg");
  logSide = loadImage("log_side.jpg");
  logTop = loadImage("log_top.jpg");
  doorTop = loadImage("door_top.jpg");
  doorBottom = loadImage("door_bottom.jpg");

  // Start position - above the house looking down
  eyeX = 200 + 2.5f * gridSize; // Center of house
  eyeY = 300;                   // Above the house
  eyeZ = 200 + 2.5f * gridSize + 400; // Back from house
  focusX = 200 + 2.5f * gridSize;     // Look at house center
  focusY = 0;                         // Look at ground level
  focusZ = 200 + 2.5f * gridSize;     // Look at house center

  // Calculate initial view angles
  float dx = focusX - eyeX;
  float dy = focusY - eyeY;
  float dz = focusZ - eyeZ;
  float horizDist = sqrt(dx*dx + dz*dz);
  lrA = atan2(dz, dx);
  udA = atan2(dy, horizDist);

  try {
    rbt = new Robot();
    java.awt.Point loc = ((java.awt.Component) surface.getNative()).getLocationOnScreen();
    rbt.mouseMove(loc.x + width/2, loc.y + height/2);
  } catch(Exception e) {
    println("Couldn't initialize mouse control: " + e);
  }

  noCursor();
  smooth();
}

void draw() {
  updateDayNight();
  lights();
  updateMovement();
  controlCamera();

  drawGrassFloor();
  drawMapTerrain();
  drawHouse();
  
  // Display controls
  camera();
  hint(DISABLE_DEPTH_TEST);
  fill(255);
  textSize(16);
  text("WASD: Move | Mouse: Look | SPACE: Up | SHIFT: Down", 20, 30);
  hint(ENABLE_DEPTH_TEST);
}

void updateDayNight() {
  sunAngle = (sunAngle + 0.002f) % TWO_PI;
  float sky = map(cos(sunAngle), -1, 1, 20, 200);
  background(20, 20, sky);
  directionalLight(255, 255, 255, -cos(sunAngle), sin(sunAngle), -0.5);
}

void drawGrassFloor() {
  noStroke();
  for (int x = 0; x < mapW; x++) {
    for (int z = 0; z < mapH; z++) {
      if (mapImg.pixels[z * mapW + x] == color(255)) {
        pushMatrix();
        translate(x * gridSize, 0, z * gridSize);
        drawBlock(grass, grass, grass);
        popMatrix();
      }
    }
  }
}

void drawMapTerrain() {
  noStroke();
  for (int x = 0; x < mapW; x++) {
    for (int z = 0; z < mapH; z++) {
      if (mapImg.pixels[z * mapW + x] == color(0)) {
        pushMatrix();
        translate(x * gridSize, 0, z * gridSize);
        drawBlock(glass, glass, glass);
        popMatrix();
      }
    }
  }
}

void drawHouse() {
  float ox = 200; // House X position
  float oz = 200; // House Z position
  float oy = 0;   // Ground level

  // Floor (at ground level)
  for (int x = 0; x < 6; x++) {
    for (int z = 0; z < 6; z++) {
      pushMatrix();
      translate(ox + x*gridSize, oy, oz + z*gridSize);
      drawBlock(birch, birch, birch);
      popMatrix();
    }
  }

  // Walls (built upward from ground)
  for (int level = 1; level <= 4; level++) {
    float yPos = oy - level * gridSize;
    
    // Corner pillars
    for (int xi = 0; xi < 2; xi++) {
      for (int zi = 0; zi < 2; zi++) {
        pushMatrix();
        translate(ox + xi*5*gridSize, yPos, oz + zi*5*gridSize);
        drawBlock(logTop, logTop, logSide);
        popMatrix();
      }
    }
    
    // Glass walls between pillars
    for (int x = 1; x < 5; x++) {
      pushMatrix();
      translate(ox + x*gridSize, yPos, oz);
      drawBlock(glass, glass, glass);
      popMatrix();
      pushMatrix();
      translate(ox + x*gridSize, yPos, oz + 5*gridSize);
      drawBlock(glass, glass, glass);
      popMatrix();
    }
    for (int z = 1; z < 5; z++) {
      pushMatrix();
      translate(ox, yPos, oz + z*gridSize);
      drawBlock(glass, glass, glass);
      popMatrix();
      pushMatrix();
      translate(ox + 5*gridSize, yPos, oz + z*gridSize);
      drawBlock(glass, glass, glass);
      popMatrix();
    }
  }

  // Door (2 blocks tall)
  pushMatrix();
  translate(ox + 2*gridSize, oy, oz);
  drawBlock(doorTop, doorBottom, doorBottom);
  popMatrix();
  pushMatrix();
  translate(ox + 2*gridSize, oy - gridSize, oz);
  drawBlock(doorTop, doorBottom, doorBottom);
  popMatrix();

  // Roof (top level)
  for (int x = 0; x < 6; x++) {
    for (int z = 0; z < 6; z++) {
      pushMatrix();
      translate(ox + x*gridSize, oy - 5*gridSize, oz + z*gridSize);
      drawBlock(birch, birch, birch);
      popMatrix();
    }
  }
}

void updateMovement() {
  float mx = (wkey ? 1 : 0) - (skey ? 1 : 0);
  float mz = (dkey ? 1 : 0) - (akey ? 1 : 0);
  float my = (spaceKey ? 1 : 0) - (shiftKey ? 1 : 0);

  PVector fwd = new PVector(cos(lrA), 0, sin(lrA));
  PVector right = new PVector(-fwd.z, 0, fwd.x);
  PVector up = new PVector(0, 1, 0);
  
  PVector mv = fwd.mult(mx).add(right.mult(mz)).add(up.mult(my));

  if (mv.mag() > 0) {
    mv.normalize().mult(speed);
    eyeX += mv.x;
    eyeY += mv.y;
    eyeZ += mv.z;
  }
}

void controlCamera() {
  float ms = 0.003f;
  lrA += (mouseX - pmouseX) * ms;
  udA -= (mouseY - pmouseY) * ms;
  udA = constrain(udA, -PI/2.2, PI/2.2);

  float dx = cos(udA) * cos(lrA);
  float dy = sin(udA);
  float dz = cos(udA) * sin(lrA);

  focusX = eyeX + dx * 300;
  focusY = eyeY + dy * 300;
  focusZ = eyeZ + dz * 300;

  camera(eyeX, eyeY, eyeZ, focusX, focusY, focusZ, upX, upY, upZ);

  try {
    java.awt.Point loc = ((java.awt.Component) surface.getNative()).getLocationOnScreen();
    rbt.mouseMove(loc.x + width/2, loc.y + height/2);
  } catch(Exception e){}
}

void drawBlock(PImage top, PImage bottom, PImage side) {
  textureMode(NORMAL);
  
  // Top
  beginShape(QUADS);
  texture(top);
  vertex(0, 0, 0, 0, 0);
  vertex(gridSize, 0, 0, 1, 0);
  vertex(gridSize, 0, gridSize, 1, 1);
  vertex(0, 0, gridSize, 0, 1);
  endShape();

  // Bottom
  beginShape(QUADS);
  texture(bottom);
  vertex(0, gridSize, 0, 0, 0);
  vertex(gridSize, gridSize, 0, 1, 0);
  vertex(gridSize, gridSize, gridSize, 1, 1);
  vertex(0, gridSize, gridSize, 0, 1);
  endShape();

  // Front
  beginShape(QUADS);
  texture(side);
  vertex(0, 0, gridSize, 0, 0);
  vertex(gridSize, 0, gridSize, 1, 0);
  vertex(gridSize, gridSize, gridSize, 1, 1);
  vertex(0, gridSize, gridSize, 0, 1);
  endShape();

  // Back
  beginShape(QUADS);
  texture(side);
  vertex(gridSize, 0, 0, 0, 0);
  vertex(0, 0, 0, 1, 0);
  vertex(0, gridSize, 0, 1, 1);
  vertex(gridSize, gridSize, 0, 0, 1);
  endShape();

  // Left
  beginShape(QUADS);
  texture(side);
  vertex(0, 0, 0, 0, 0);
  vertex(0, 0, gridSize, 1, 0);
  vertex(0, gridSize, gridSize, 1, 1);
  vertex(0, gridSize, 0, 0, 1);
  endShape();

  // Right
  beginShape(QUADS);
  texture(side);
  vertex(gridSize, 0, gridSize, 0, 0);
  vertex(gridSize, 0, 0, 1, 0);
  vertex(gridSize, gridSize, 0, 1, 1);
  vertex(gridSize, gridSize, gridSize, 0, 1);
  endShape();
}

void keyPressed() {
  wkey = key == 'w' || key == 'W';
  skey = key == 's' || key == 'S';
  akey = key == 'a' || key == 'A';
  dkey = key == 'd' || key == 'D';
  spaceKey = key == ' ';
  shiftKey = key == CODED && keyCode == SHIFT;
}

void keyReleased() {
  if (key == 'w' || key == 'W') wkey = false;
  if (key == 's' || key == 'S') skey = false;
  if (key == 'a' || key == 'A') akey = false;
  if (key == 'd' || key == 'D') dkey = false;
  if (key == ' ') spaceKey = false;
  if (key == CODED && keyCode == SHIFT) shiftKey = false;
}

void mouseMoved() {
  // Needed for camera control
}
