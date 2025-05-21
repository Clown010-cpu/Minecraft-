boolean wkey, akey, skey, dkey;
float eyeX, eyeY, eyeZ, focusX, focusY, focusZ, upX, upY, upZ;
float leftRightHeadAngle, upDownHeadAngle;

void setup(){
  size(800, 600, P3D);
  textureMode(NORMAL);
  wkey = akey = skey = dkey = false;
  eyeX = width/2;
  eyeY = height/2;
  eyeZ = 0;
  focusX = width/2;
  focusY = height/2;
  focusZ = 10;
  upX = 0;
  upY = 1;
  upZ = 1;
  leftRightHeadAngle = radians(270);
  noCursor();
}

void draw(){
  background(0);
  camera(eyeX, eyeY, eyeZ, focusX, focusY, focusZ, upX, upY, upZ);
  drawFloor();
  drawFocalPoint();
  controlCamera();
}

void drawFocalPoint(){
pushMatrix();
translate(focusX, focusY, focusZ);
sphere(5);
popMatrix();

}

void drawFloor(){
  stroke(255);
  for (int x = -2000; x <= 2000; x = x + 100) {
    line(x, height, -2000, x, height, 2000);
    line(-2000, height, x, 2000, height, x);
    
    
  }
}

void controlCamera(){
  if (wkey) eyeZ = eyeZ - 10;
  if (skey) eyeZ = eyeZ + 10;
  if (akey) eyeX = eyeX - 10;
  if (dkey) eyeX = eyeX + 10;
  
  leftRightHeadAngle = leftRightHeadAngle + (mouseX - pmouseX)*0.01;
  upDownHeadAngle = upDownHeadAngle + (mouseY - pmouseY)*0.01;
  if(upDownHeadAngle > PI/2.5) upDownHeadAngle = PI/2.5;
  if(upDownHeadAngle < -PI/2.5) upDownHeadAngle = -PI/2.5;
  
    focusX = eyeX + cos(leftRightHeadAngle)*300;
    focusZ = eyeZ + sin(leftRightHeadAngle)*300;
    focusY = eyeY + tan(upDownHeadAngle)*300;
    
    println(eyeX, eyeY, eyeZ);
}











void keyPressed(){
  if (key == 'W'|| key == 'w') wkey = true;
  if (key == 'A'|| key == 'a') akey = true;
  if (key == 'D'|| key == 'd') dkey = true;
  if (key == 'S'|| key == 's') skey = true;
}

void keyReleased(){
  if (key == 'W'|| key == 'w') wkey = false;
  if (key == 'A'|| key == 'a') akey = false;
  if (key == 'D'|| key == 'd') dkey = false;
  if (key == 'S'|| key == 's') skey = false;
}
