import java.awt.Robot;
import java.util.ArrayList;

PImage mapImg, grass, birch, glass, logSide, logTop, doorTop, doorBottom, snowImg;
Robot rbt;

boolean wkey, akey, skey, dkey, spaceKey, shiftKey;
float eyeX, eyeY, eyeZ, focusX, focusY, focusZ;
float upX = 0, upY = 1, upZ = 0;
float lrA, udA;
final float gridSize = 100;
int mapW = 25, mapH = 25;
float sunAngle = 0, speed = 8;

ArrayList<Snowball> snowballs = new ArrayList<Snowball>();
ArrayList<Target> targets = new ArrayList<Target>();
int score = 0;
int totalEnemies = 10;
float lastRespawnTime = 0;
float respawnInterval = 3.0f;

void setup() {
  size(1200, 800, P3D);
  textureMode(NORMAL);
  smooth();
  
  mapImg = createImage(mapW, mapH, RGB);
  mapImg.loadPixels();
  for (int i = 0; i < mapImg.pixels.length; i++) {
    int x = i % mapW, y = i / mapW;
    mapImg.pixels[i] = (x % 4 == 0 && y % 4 == 0) ? color(0) : color(255);
  }
  mapImg.updatePixels();
  
  grass = loadImage("grass.jpg");
  birch = loadImage("birch.jpg");
  glass = loadImage("glass.jpg");
  logSide = loadImage("log_side.jpg");
  logTop = loadImage("log_top.jpg");
  doorTop = loadImage("door_top.jpg");
  doorBottom = loadImage("door_bottom.jpg");
  snowImg = loadImage("snowball.png");
  
  eyeX = 200 + 2.5f * gridSize;
  eyeY = 300;
  eyeZ = 200 + 2.5f * gridSize + 400;
  focusX = 200 + 2.5f * gridSize;
  focusY = 0;
  focusZ = 200 + 2.5f * gridSize;
  
  float dx = focusX - eyeX, dy = focusY - eyeY, dz = focusZ - eyeZ;
  float horizDist = sqrt(dx * dx + dz * dz);
  lrA = atan2(dz, dx);
  udA = atan2(dy, horizDist);
  
  spawnEnemies();
  
  try {
    rbt = new Robot();
    centerMouse();
  } catch (Exception e) {
    println("Robot initialization failed: " + e);
  }
  noCursor();
}

void spawnEnemies() {
  targets.clear();
  for (int i = 0; i < totalEnemies; i++) {
    float x = random(-mapW * gridSize/2, mapW * gridSize/2);
    float z = random(-mapH * gridSize/2, mapH * gridSize/2);
    
    int enemyType = (int)random(3);
    PImage tex;
    int points;
    float sizeScale;
    
    switch(enemyType) {
      case 0:
        tex = grass;
        points = 10;
        sizeScale = 1.0;
        break;
      case 1:
        tex = birch;
        points = 20;
        sizeScale = 1.2;
        break;
      case 2:
        tex = glass;
        points = 30;
        sizeScale = 0.8;
        break;
      default:
        tex = grass;
        points = 10;
        sizeScale = 1.0;
    }
    
    targets.add(new Target(x, 0, z, tex, points, sizeScale));
  }
}

void centerMouse() {
  java.awt.Point loc = ((java.awt.Component) surface.getNative()).getLocationOnScreen();
  rbt.mouseMove(loc.x + width/2, loc.y + height/2);
}

void draw() {
  sunAngle = (sunAngle + 0.002f) % TWO_PI;
  float sky = map(cos(sunAngle), -1, 1, 20, 200);
  background(20, 20, sky);
  directionalLight(255, 255, 255, -cos(sunAngle), sin(sunAngle), -0.5);
  lights();
  
  updateMovement();
  controlCamera();
  
  drawGrassFloor();
  drawMapTerrain();
  drawHouse();
  
  for (int i = snowballs.size() - 1; i >= 0; i--) {
    Snowball sb = snowballs.get(i);
    sb.update();
    sb.display();
    if (sb.hitTargets(targets) || sb.offWorld(mapW * gridSize)) {
      snowballs.remove(i);
    }
  }
  
  checkRespawn();
  
  for (Target t : targets) {
    t.display();
    if (!t.hit) {
      pushMatrix();
      translate(t.pos.x, t.pos.y + t.size + 20, t.pos.z);
      noStroke();
      fill(255, 255, 0);
      box(20);
      popMatrix();
    }
  }
  
  camera();
  hint(DISABLE_DEPTH_TEST);
  fill(255);
  textSize(16);
  text("WASD: Move | Mouse: Look | SPACE: Up | SHIFT: Down", 20, 30);
  text("Click to shoot snowball", 20, 50);
  text("Score: " + score, 20, 70);
  hint(ENABLE_DEPTH_TEST);
}

void checkRespawn() {
  if (millis()/1000.0 - lastRespawnTime > respawnInterval) {
    boolean allHit = true;
    for (Target t : targets) {
      if (!t.hit) {
        allHit = false;
        break;
      }
    }
    if (allHit) {
      spawnEnemies();
    }
    lastRespawnTime = millis()/1000.0;
  }
}

void mousePressed() {
  if (mouseButton == LEFT) {
    PVector dir = PVector.sub(new PVector(focusX, focusY, focusZ), new PVector(eyeX, eyeY, eyeZ)).normalize();
    PVector vel = PVector.mult(dir, 40);
    snowballs.add(new Snowball(new PVector(eyeX, eyeY, eyeZ), vel));
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
    centerMouse();
  } catch (Exception e) {
    println("Mouse centering failed: " + e);
  }
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
  float ox = 200, oz = 200, oy = 0;
  for (int x = 0; x < 6; x++) {
    for (int z = 0; z < 6; z++) {
      pushMatrix();
      translate(ox + x * gridSize, oy, oz + z * gridSize);
      drawBlock(birch, birch, birch);
      popMatrix();
    }
  }
  for (int level = 1; level <= 4; level++) {
    float yPos = oy - level * gridSize;
    for (int xi = 0; xi < 2; xi++) {
      for (int zi = 0; zi < 2; zi++) {
        pushMatrix();
        translate(ox + xi * 5 * gridSize, yPos, oz + zi * 5 * gridSize);
        drawBlock(logTop, logTop, logSide);
        popMatrix();
      }
    }
    for (int x = 1; x < 5; x++) {
      pushMatrix();
      translate(ox + x * gridSize, yPos, oz);
      drawBlock(glass, glass, glass);
      popMatrix();
      pushMatrix();
      translate(ox + x * gridSize, yPos, oz + 5 * gridSize);
      drawBlock(glass, glass, glass);
      popMatrix();
    }
    for (int z = 1; z < 5; z++) {
      pushMatrix();
      translate(ox, yPos, oz + z * gridSize);
      drawBlock(glass, glass, glass);
      popMatrix();
      pushMatrix();
      translate(ox + 5 * gridSize, yPos, oz + z * gridSize);
      drawBlock(glass, glass, glass);
      popMatrix();
    }
  }
  pushMatrix();
  translate(ox + 2 * gridSize, oy, oz);
  drawBlock(doorTop, doorBottom, doorBottom);
  popMatrix();
  pushMatrix();
  translate(ox + 2 * gridSize, oy - gridSize, oz);
  drawBlock(doorTop, doorBottom, doorBottom);
  popMatrix();
  for (int x = 0; x < 6; x++) {
    for (int z = 0; z < 6; z++) {
      pushMatrix();
      translate(ox + x * gridSize, oy - 5 * gridSize, oz + z * gridSize);
      drawBlock(birch, birch, birch);
      popMatrix();
    }
  }
}

void drawBlock(PImage top, PImage bottom, PImage side) {
  textureMode(NORMAL);
  beginShape(QUADS);
  texture(top);
  vertex(0, 0, 0, 0, 0);
  vertex(gridSize, 0, 0, 1, 0);
  vertex(gridSize, 0, gridSize, 1, 1);
  vertex(0, 0, gridSize, 0, 1);
  endShape();
  beginShape(QUADS);
  texture(bottom);
  vertex(0, gridSize, 0, 0, 0);
  vertex(gridSize, gridSize, 0, 1, 0);
  vertex(gridSize, gridSize, gridSize, 1, 1);
  vertex(0, gridSize, gridSize, 0, 1);
  endShape();
  beginShape(QUADS);
  texture(side);
  vertex(0, 0, gridSize, 0, 0);
  vertex(gridSize, 0, gridSize, 1, 0);
  vertex(gridSize, gridSize, gridSize, 1, 1);
  vertex(0, gridSize, gridSize, 0, 1);
  endShape();
  beginShape(QUADS);
  texture(side);
  vertex(gridSize, 0, 0, 0, 0);
  vertex(0, 0, 0, 1, 0);
  vertex(0, gridSize, 0, 1, 1);
  vertex(gridSize, gridSize, 0, 0, 1);
  endShape();
  beginShape(QUADS);
  texture(side);
  vertex(0, 0, 0, 0, 0);
  vertex(0, 0, gridSize, 1, 0);
  vertex(0, gridSize, gridSize, 1, 1);
  vertex(0, gridSize, 0, 0, 1);
  endShape();
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

class Snowball {
  PVector pos, vel;
  float r = 15;
  Snowball(PVector p, PVector v) { pos = p.copy(); vel = v.copy(); }
  void update() { pos.add(vel); vel.y += 0.6; }
  boolean offWorld(float size) {
    return pos.y > size || pos.y < -size || abs(pos.x - eyeX) > 2 * size || abs(pos.z - eyeZ) > 2 * size;
  }
  boolean hitTargets(ArrayList<Target> ts) {
    for (Target t : ts) {
      if (!t.hit && PVector.dist(pos, t.pos) < t.size / 2 + r) {
        t.hit = true;
        score += t.points;
        return true;
      }
    }
    return false;
  }
  void display() {
    pushMatrix();
    translate(pos.x, pos.y, pos.z);
    textureMode(NORMAL);
    noStroke();
    beginShape(QUADS);
    texture(snowImg);
    vertex(-r, -r, 0, 0, 0);
    vertex(r, -r, 0, 1, 0);
    vertex(r, r, 0, 1, 1);
    vertex(-r, r, 0, 0, 1);
    endShape();
    popMatrix();
  }
}

class Target {
  PVector pos;
  float size;
  PImage tex;
  boolean hit = false;
  int points;
  Target(float x, float y, float z, PImage t, int pts, float sizeScale) {
    size = gridSize * 1.2 * sizeScale;
    pos = new PVector(x, y + size / 2, z);
    tex = t;
    points = pts;
  }
  void display() {
    if (hit) return;
    pushMatrix();
    translate(pos.x, pos.y, pos.z);
    noStroke();
    textureMode(NORMAL);
    beginShape(QUADS);
    texture(tex);
    vertex(-size / 2, 0, -size / 2, 0, 0);
    vertex(size / 2, 0, -size / 2, 1, 0);
    vertex(size / 2, size, -size / 2, 1, 1);
    vertex(-size / 2, size, -size / 2, 0, 1);
    endShape();
    popMatrix();
  }
  void mousePressed() {
  if (mouseButton == LEFT) {
    PVector dir = PVector.sub(new PVector(focusX, focusY, focusZ), new PVector(eyeX, eyeY, eyeZ)).normalize();
    PVector vel = PVector.mult(dir, 40);
    snowballs.add(new Snowball(new PVector(eyeX, eyeY, eyeZ), vel));
  }
}

}
