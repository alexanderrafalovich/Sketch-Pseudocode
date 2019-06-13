import java.util.Collections;

PGraphics pg;

PShader csb;

int pgWidth = 1920;
int pgHeight = 1080;

File dir;
String[] imageFileList;
ArrayList<PImage> images;
float initialBrushRadius = 270.0;
float initialOpacity = 255.0;

int steps = 12*30;
int currentStep = 0;

float brushRadius;
float opacity;

boolean shouldClearScreen = true;

float perlinOffsetX = 0.0;
float perlinOffsetY = 0.0;

float probabilityBlendAdd = 0.84;
float probabilityBlendIncrement = 0.02;

float idealIntensity = 30.0;//dark: 60 mid: 120 lighter:160 high:220

float[] tintMultiplier = {0.8,0.8,0.8};
float tintMultiplierIncrement = 0.1;


int season = 0;
int seasonsPerYear = 8;
int year = 0;

Drawer drawer;

//----------------------------
void setup() {
  dir = new File(dataPath(""));
  size(960, 540, P3D);
  //fullScreen(P3D);
  //frameRate(60);
  noStroke();
  //noCursor();
  background(0,0,0);

  csb = loadShader( "ContrastSaturationBrightness.glsl" );
  csb.set("contrast", 1.05);
  csb.set("saturation", 1.05);
  csb.set("brightness", 1.05);

  pg = createGraphics(pgWidth, pgHeight, P3D);
  pg.beginDraw();
  pg.noStroke();
  pg.rectMode(CENTER);
  pg.background(0,0,0);
  pg.endDraw();

  brushRadius = initialBrushRadius;
  opacity = initialOpacity;

  loadImages();
  
  float percentBorder = 0.1;

  drawer = new Drawer( 
    pgWidth/2, pgHeight/2, 
    0.001, 
    1.0, 
    pgWidth*percentBorder, pgHeight*(percentBorder*3.0), pgWidth*(1-percentBorder), pgHeight*(1-percentBorder*3.0)
    );
}

//----------------------------
void draw() {
  if (shouldClearScreen) {
    shouldClearScreen = false;
    pg.beginDraw();
    //pg.background(255,255,255,0);
    pg.endDraw();
  }
  if (mousePressed) {
    drawMemesAtPosition(mouseX, mouseY);
  }

  //int forceRow = floor(drawer._posX/forceWidth);
  //int forceCol = floor(drawer._posY/forceHeight);
  //if(forceRow < 0 || forceRow >= forceWidth || forceCol < 0 || forceCol >= forceHeight){
  //do nothing, drawer should bounce on its own
  //}else{
  drawer.ApplyForce(
    (noise(perlinOffsetX, 0)-0.5)*3.0, 
    (noise(0, perlinOffsetY)-0.5)*3.0
    //forceMatrix[forceRow][forceCol][0] * 20.0,
    //forceMatrix[forceRow][forceCol][1] * 20.0
    );
  perlinOffsetX += 0.03;
  perlinOffsetY += 0.031;
  //}
  drawer.UpdatePosition();
  //stroke(0);
  //fill(255);  
  //ellipse(drawer._posX,drawer._posY,50,50);
  drawMemesAtPosition((int)drawer._posX, (int)drawer._posY);

  currentStep++;
  if (currentStep>steps) {
    print("Applying csb filter... ");
    pg.filter(csb);
    imageMode(CORNER);
    image(pg, 0, 0, width, height);
    println("Applied.");

    float[] intensities = calculateIntensity();
    //Adjust brightness by changing probability of blending via Add vs Multiply
    if (intensities[0]>idealIntensity) {
      probabilityBlendAdd -= probabilityBlendIncrement;
    } else if (intensities[0]<idealIntensity) {
      probabilityBlendAdd += probabilityBlendIncrement;
    }
    //Adjust rgb tinting by adjusting tint multiplier
    //set to 1 to skip the brightness operator
    int indexOfLargest = 1;
    int indexOfSmallest = 1;
    for (int i = 2; i < intensities.length; i++) {
      if (intensities[i]>intensities[indexOfLargest]) indexOfLargest = i;
      if (intensities[i]<intensities[indexOfSmallest]) indexOfSmallest = i;
    }
    tintMultiplier[indexOfLargest - 1] -= tintMultiplierIncrement;
    tintMultiplier[indexOfSmallest - 1] += tintMultiplierIncrement;
    println("Tint Multipliers: ");
    println(tintMultiplier);
    print("Probability Add: ");
    println(probabilityBlendAdd);

    print("Saving file... ");
    pg.save(dataPath("screen"+floor(random(100000000.0))+".png"));
    println("Saved.");
    shouldClearScreen = true;
    drawer.Reset();
    opacity = initialOpacity;
    brushRadius = initialBrushRadius;
    currentStep = 0;
    loadImages();
    print("Deleting oldest... ");
    deleteOldestFile();
    println("Deleted.");
    season += 1;
    if (season>=seasonsPerYear) {
      season = 0;
      year += 1;
    }
  } else {
    if (currentStep<steps*0.1) {
      brushRadius = initialBrushRadius*((noise(perlinOffsetX*0.4)+0.6));
      opacity = initialOpacity;
    } else {
      brushRadius = initialBrushRadius*((noise(perlinOffsetX*0.6)+0.2));
      opacity = initialOpacity*((noise(perlinOffsetY*0.6)+0.2));
    }
  }
  imageMode(CORNER);
  image(pg, 0, 0, width, height);
}

//----------------------------
void mouseWheel(MouseEvent event) {
  float e = event.getCount();
  if (e>0) {
    brushRadius = (brushRadius*e*1.1);
  } else {
    brushRadius = (brushRadius*e*-0.9);
  }
  if (brushRadius<1) {
    brushRadius = 1;
  }
}

//----------------------------
void keyPressed() {

  if (key == CODED) {
    println(keyCode);
    //for UP, DOWN, LEFT, RIGHT, ALT, CONTROL, SHIFT
    if (keyCode == DOWN) {
      opacity = opacity*0.9;
      if (opacity < 1.0) {
        opacity = 1.0;
      }
    } else if (keyCode == UP) {
      opacity = opacity*1.1;
      if (opacity > 255.0) {
        opacity = 255.0;
      }
    }
  } else {
    //ASCII spec includes BACKSPACE, TAB, ENTER, RETURN, ESC, DELETE
    if (key == DELETE) {
      pg.save(dataPath("screen"+floor(random(100000000.0))+".png"));
    } else if (key == ENTER || key == RETURN) {
      shouldClearScreen = true;
    }
  }
}

//-----------------------
void drawMemesAtPosition(int x, int y) {
  float vertexBiasMiddle = 1.4f;
  float vertexBiasSide = 0.8f;

  int numberImages = images.size();
  Collections.shuffle(images);
  for (int i = 0; i < numberImages; i++) {
    int xPos = x ;//+ (int)(random(brushRadius*2) - brushRadius);
    int yPos = y ;//+ (int)(random(brushRadius*2) - brushRadius);
    int imgWidth = (int)(random(brushRadius)+brushRadius);
    int imgHeight = (int)(random(brushRadius)+brushRadius);
    pg.beginDraw();
    float blendRandom = random(1.0);
    if (blendRandom < probabilityBlendAdd) {
      pg.blendMode(ADD);
    } else {
      pg.blendMode(MULTIPLY);
    }
    pg.beginShape();
    pg.texture(images.get(i));
    pg.textureMode(NORMAL);
    pg.tint(
      noise(perlinOffsetX*0.235121 +12.111)*255*tintMultiplier[0], 
      noise(perlinOffsetX*0.112131 + perlinOffsetY*.1501218 + 19.2)*255*tintMultiplier[1], 
      noise(perlinOffsetY*0.197216+21.3)*255*tintMultiplier[2], 
      opacity
      );
    //pg.vertex(100,100,0,0);
    //pg.vertex(1000,100,1,0);
    //pg.vertex(1000,1000,1,1);
    //pg.vertex(100,1000,0,1);


    pg.vertex(xPos, yPos-(int)(random(vertexBiasMiddle)*(imgHeight/2.0)), 0, 0);
    pg.vertex(xPos+(int)(random(vertexBiasSide)*(imgWidth/2.0)), yPos, 1, 0);
    pg.vertex(xPos, yPos+(int)(random(vertexBiasMiddle)*(imgHeight/2.0)), 1, 1);
    pg.vertex(xPos-(int)(random(vertexBiasSide)*(imgWidth/2.0)), yPos, 0, 1);
    pg.endShape();
    pg.endDraw();
    pg.blendMode(BLEND);
  }
}

void loadImages() {
  imageFileList = dir.list();
  images = new ArrayList<PImage>();

  for (String s : imageFileList) {
    images.add(loadImage(s));
  }
}

void deleteOldestFile() {
  File oldestFile = new File(dataPath(dir.list()[0]));
  for (File f : dir.listFiles()) {
    if (f.lastModified() < oldestFile.lastModified()) {
      oldestFile = f;
    }
  }
  oldestFile.delete();
}

float[] calculateIntensity() {
  //[0] -> brightness
  //[1] -> red
  //[2] -> blue
  //[3] -> green
  float totalPixels = pgWidth*pgHeight;
  double[] totalIntensity = {0.0, 0.0, 0.0, 0.0};

  println("Calculating Intensity...");
  pg.loadPixels();
  for (int x = 0; x<pgWidth; x++) {
    for (int y = 0; y<pgHeight; y++) {    
      color c = pg.pixels[y*pgWidth+x];
      totalIntensity[0] += (double)brightness(c);
      totalIntensity[1] += (double)red(c);
      totalIntensity[2] += (double)green(c);
      totalIntensity[3] += (double)blue(c);
    }
  }
  float[] returns = {
    (float)totalIntensity[0]/totalPixels, 
    (float)totalIntensity[1]/totalPixels, 
    (float)totalIntensity[2]/totalPixels, 
    (float)totalIntensity[3]/totalPixels
  };
  println("Intensities: ");
  println(returns);
  
  return returns;
}
