// Sound variables
import processing.sound.*;
SoundFile soundLeak;
SoundFile soundPop1;
SoundFile soundPop2;
boolean allowToPlay = true;

// UI elements
import controlP5.*;
ControlP5 cp5;
int buttonWidth = 120;
int sliderWidth = 500;

// State machine variables
int uiState = 0;  // 0: start, 1: play, 2: rate, 3: finish
PFont messageF;
PFont p;

// Serial
import processing.serial.*;
Serial myPort; 

float pos = 0;
int[] randomarray =  new int[27];
int idx = 0;

int lastRequestTime = 0;
int currRequestTime = 0;
int requestInterval = 50;

int startExitTime = 0;
int currExitTime = 0;
int exitInterval = 1000;   // time from playing the sound to switching to rate page
boolean resetReady = false;

void setup() {
  size(1280, 720);
  background(255);
  generateRandomArray();    
  
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
   cp5.addButton("quit")
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
   cp5.getController("quit").moveTo("finishTab");
    
  // Load a soundfile from the /data folder of the sketch and play it back
  soundLeak = new SoundFile(this, "balloon.wav");
  soundPop1 = new SoundFile(this, "pop1.wav");
  soundPop2 = new SoundFile(this, "pop2.wav");
  //file.play();
}      

void draw() {
  background(255);
  switch (uiState) {
    case 0:    // start
      updateStart();
    break;
    case 1:    // play
      cp5.getTab("playTab").bringToFront();
      if (!resetReady) {
        if (myPort.available() > 0) {
          String inString = myPort.readStringUntil('\n');
          inString = trim(inString);
          println(inString);
          println(inString.equals("T"));
          if (inString.equals("T")) resetReady = true;
        }
      } else {
        updatePlay();
      }
    break;
    case 2:    // rate
      cp5.getTab("rateTab").bringToFront();
    break;
    case 3:    // Finish
      cp5.getTab("finishTab").bringToFront();
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
  
  
  // request position from Arduino
  currRequestTime = millis();
  if (currRequestTime - lastRequestTime > requestInterval) {
    myPort.write("R");
    lastRequestTime = currRequestTime;
  }
  // Receive position from Arduino
  if (myPort.available() > 0) {
    String inString = myPort.readStringUntil('\n');
    if (inString != null) {
      pos = float(inString);
      //println(pos);
    }  
  }
  
  // Change shape based on position
  float a = 0.01*(pos);
  float rad = 200;
  float rad1 = rad*(1+a);
  float rad2 = rad/(1+a);
  noStroke();
  fill(255,0,0);
  ellipse(width/2, height/2-rad2/2, rad1, rad2);
  fill(0);
  rect(0, height/2-50, width, height/2);
  
  // Exit condition, if position > 200, play sound
  if (pos > 200) {
    if (allowToPlay) {  // ensure sound played only once
      playOneSound(randomarray[idx]);
      allowToPlay = false;
      startExitTime = millis();
    }
  }
  if (!allowToPlay) {
    if (millis() - startExitTime > exitInterval) {
      myPort.write("S");    // Tell Aruidno to move back to WAIT_FOR_CMD state
      myPort.clear();
      resetReady = false;
      uiState = 2;
      println("change to state 2");
    }
    
  }
}

void controlEvent(ControlEvent theEvent) {
  if(theEvent.isController()) { 
    if(theEvent.getController().getName()=="start") {
     myPort.write(str(randomarray[idx]));
     println(randomarray[idx]);
     println("change to state 1");
     uiState = 1;
    }
    if(theEvent.getController().getName()=="confirm") {
     idx++;
     if (idx == 27) {  // finish
       println("change to state 3");
       uiState = 3;
     } else {
       myPort.write(str(randomarray[idx]));
       myPort.clear();
       println(randomarray[idx]);
       println("change to state 1");
       pos = 0;     // reset postion value, will be updated later 
       uiState = 1;
       allowToPlay = true;
     }
    }
    if(theEvent.getController().getName()=="quit") {
      exit();
    }
    
  }
}

void playOneSound(int cs) {
  if (cs % 3 == 1) soundPop1.play();
  else if (cs % 3 == 2) soundPop2.play();
  else if (cs == 6) soundLeak.play();
}

// generate random sequence of numbers from 0-9
// each repeated 3 times, representing haptic-audio conditions
void generateRandomArray() {
  for(int i = 0; i < randomarray.length; i++) {
    randomarray[i] = i % 9;
  }
  for (int j = 0; j < randomarray.length; j++) {
    int temp = randomarray[j]; 
    int x = (int)random(0, randomarray.length);  
     randomarray[j] = randomarray[x];
     randomarray[x] = temp;
  }
  printArray(randomarray);
}
