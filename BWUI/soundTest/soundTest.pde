// Sound variables
import processing.sound.*;
SoundFile file;

// UI elements
import controlP5.*;
ControlP5 cp5;

// State machine variables
int uiState = 0;  // 0: start, 1: play, 2: rate, 3: finish
PFont messageF;
PFont p;

int buttonWidth = 120;
int sliderWidth = 500;

// Serial
import processing.serial.*;
Serial myPort; 

float pos = 0;



void setup() {
  size(1280, 720);
  background(255);
  
  printArray(Serial.list());
  myPort = new Serial(this, Serial.list()[11], 115200);  //
  myPort.bufferUntil('\n');
 
  messageF = createFont("Arial", 16, true); 
  cp5 = new ControlP5(this);
  p = createFont("Verdana",16); 
  ControlFont font = new ControlFont(p);
  
  cp5.setColorForeground(0xffaa0000);
  cp5.setColorBackground(0xff660000);
  cp5.setFont(font);
  cp5.setColorActive(0xffff0000);
  // add tab
  cp5.addTab("playTab")
     .setColorBackground(color(255, 255, 255))
     .setColorLabel(color(0))
     .setColorActive(color(255,128,0));
  cp5.addTab("rateTab")
     .setColorBackground(color(255, 255, 255))
     .setColorLabel(color(0))
     .setColorActive(color(255,128,0));
  cp5.addTab("finishTab")
     .setColorBackground(color(255, 255, 255))
     .setColorLabel(color(0))
     .setColorActive(color(255,128,0));
     
  cp5.getTab("default")
     .activateEvent(false)
     .setLabel("start")
     .setId(1);
  cp5.getTab("playTab")
     .activateEvent(false)
     .setLabel("play")
     .setId(2);
   cp5.getTab("rateTab")
     .activateEvent(false)
     .setLabel("rate")
     .setId(3);
   cp5.getTab("finishTab")
     .activateEvent(false)
     .setLabel("finish")
     .setId(3);
     
   cp5.addButton("start")
     .setBroadcast(false)
     .setPosition(width/2-buttonWidth/2,400)
     .setSize(buttonWidth,40)
     .setValue(1)
     .setBroadcast(true)
     .getCaptionLabel().align(CENTER,CENTER);
   //cp5.addTextfield("description",0,0,width, 100)
   //  .setValue("Start page");
   cp5.addButton("confirm")
     .setBroadcast(false)
     .setPosition(width/2-buttonWidth/2,240)
     .setSize(buttonWidth,40)
     .setValue(1)
     .setBroadcast(true)
     .getCaptionLabel().align(CENTER,CENTER)
     ;
     
   cp5.addSlider("pleasantness")
     .setBroadcast(false)
     .setRange(0,255)
     .setValue(128)
     .setPosition(width/2-sliderWidth/2,200)
     .setSize(sliderWidth,20)
     .setBroadcast(true);
   cp5.getController("confirm").moveTo("rateTab");
   cp5.getController("pleasantness").moveTo("rateTab");  
    
  // Load a soundfile from the /data folder of the sketch and play it back
  //file = new SoundFile(this, "balloon.wav");
  //file.play();
}      

void draw() {
  background(255);
  switch (uiState) {
    case 0:    // start
      updateStart();
    break;
    case 1:    // play
      updatePlay();
    break;
    case 2:    // rate
      updateRate();
    break;
    case 3:    // Finish
      updateFinish();
    break;
  }
  
}

void updateStart(){
  cp5.getTab("default").bringToFront();
  textFont(messageF,16); 
  fill(0);                         
  textAlign(CENTER);
  text(" start page description1.",width/2,100);
  text(" start page description2.",width/2,120);
  text(" start page description3.",width/2,140);
}

void updatePlay(){
  cp5.getTab("playTab").bringToFront();
  fill(0);
  rect(100, 0, 200, height);
  //println(pos);
  if (pos > 100) {
    uiState = 2;
  }
  //delay(2000);
  //uiState = 0;
  
}

void updateRate(){
  cp5.getTab("rateTab").bringToFront();
}

void updateFinish(){
  cp5.getTab("finishTab").bringToFront();
}

void controlEvent(ControlEvent theEvent) {
  if(theEvent.isController()) { 
    if(theEvent.getController().getName()=="start") {
     myPort.write('1');
     println("1");
     uiState = 1;
     //cp5.getTab("playTab").bringToFront();
     //createRateUI();
    }
    if(theEvent.getController().getName()=="confirm") {
     uiState = 1;
     //cp5.getTab("default").bringToFront();
     //createStartUI();
    }
    
  }
}

void serialEvent (Serial myPort) {
  // get the ASCII string:
  if (myPort.available() > 0) {
    String inString = myPort.readStringUntil('\n');
    if (inString != null) {
      pos = float(inString);
    }  
  }
}
