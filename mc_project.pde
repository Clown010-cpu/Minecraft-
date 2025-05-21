float rotx, roty;

void setup(){
  size(800,800,P3D);
}

void draw(){
  background(255);
  
  translate(width/2, height/2, 0);
  
  rotateX(rotx);
  rotateY(roty);
  //rotateZ();
  
  fill(255,0,0);

  strokeWeight(3);
  sphere(300);
  
  
  
  
  
  //cube(width/2, height/2, 0, #FF0000, 200);
  //cube(0, 0, 0, #0000FF, 200);
}

void cube(float x, float y, float z, color c, float size) {
  pushMatrix();
    translate(x, y, z);
  
  rotateX(rotx);
  rotateY(roty);
  //rotateZ();
  
  fill(c);
  stroke(0);
  strokeWeight(3);
  box(size); //w,h,d
  popMatrix();
}


void mouseDragged(){
  rotx = rotx + (pmouseY - mouseY)*0.01;
  roty = roty + (pmouseX - mouseX)*-0.01;
}
