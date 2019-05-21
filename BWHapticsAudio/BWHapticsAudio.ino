/******************************************************
 * File: BWHapticsAudio
 * Description:
 *    Used for driving a 1-DOF capstan drive
 *    Communicates with Processing script via serial
 *    MUSIC 251 Spring 2019 final project
 * Author: Shenli Yuan {shenliy@stanford.edu}
 ******************************************************/

#include <DDHapticHelper.h>
float myKp = 3 ;
float myKi = 0.0; //0.12;
float myKd = 0.0; //0.01 * Kp;

/*Velocity calculation*/
float xh = 0;           // position of the handle [m]
float xh_prev;          // Distance of the handle at previous time step
float xh_prev2;
float dxh;              // Velocity of the handle
float dxh_prev;
float dxh_prev2;
float dxh_filt;         // Filtered velocity of the handle
float dxh_filt_prev;
float dxh_filt_prev2;
long velTime = 10;
long lastVelUpdate = 0;
long currVelUpdate = 0;

float Kd_vel = 0.0; //0.5;

/*force filter*/
int thisForce = 0;
#define ffWindowSize 50
float ffWindow[ffWindowSize];
int ffIndex = 0;

float positionVal = 0;

/* State machine and communication variables */
typedef enum {UPDATE_HAPTICS, WAIT_FOR_CMD, RESET_POS} HapticState_t;
HapticState_t currState = WAIT_FOR_CMD;
char cmdProcessing = '0';

unsigned long startResetTime = 0;
boolean ledState = LOW;

void setup() {
  Serial.begin(115200);

  /* PID setup */
  Input = 0;
  Setpoint = 0;
  myPID.SetMode(AUTOMATIC);
  int myRes = 12;
//  myPID.SetOutputLimits(0, pow(2, myRes));
  myPID.SetOutputLimits(-pow(2, myRes), pow(2, myRes));
  myPID.SetSampleTime(100);   // Sample time 100 micros
  analogWriteResolution(myRes);
  myPID.SetTunings(myKp, myKi, myKd);
  /* Encoder ABI setup */
  pinMode(ENC_A, INPUT);
  pinMode(ENC_B, INPUT);
  pinMode(ENC_I, INPUT);
  attachInterrupt(digitalPinToInterrupt(ENC_A), updateEncoderAB, CHANGE);
  attachInterrupt(digitalPinToInterrupt(ENC_B), updateEncoderAB, CHANGE);
  attachInterrupt(digitalPinToInterrupt(ENC_I), updateEncoderI, RISING);
  /* Motor setup */
  pinMode(pwmPin0, OUTPUT);
  pinMode(pwmPin1, OUTPUT);
  analogWriteFrequency(pwmPin0, 18000);
  analogWriteFrequency(pwmPin1, 18000);
  pinMode(enablePin0, OUTPUT);
  digitalWrite(enablePin0, HIGH);
  /* Button setup */
  debouncer.attach(buttonPin, INPUT_PULLUP);
  debouncer.interval(25);
  for (int i = 0; i < filterWindowSize; i++) {
    filterWindow[i] = 0;
  }
  pinMode(LED_BUILTIN, OUTPUT);
}


void loop() {
  switch (currState) {
    case WAIT_FOR_CMD:
      if (Serial.available() > 0) {
        cmdProcessing = Serial.read();
        currState = RESET_POS;
        startResetTime = millis();
        
        ledState = !ledState;
        digitalWrite(LED_BUILTIN, ledState);
        
//        delay(100);
        analogWrite(pwmPin0, 100);
        analogWrite(pwmPin1, 0);
      }
//      if (cmdProcessing != '0') {
//        
//      }
    break;
    case UPDATE_HAPTICS:
      updateHaptics();
    break;
    case RESET_POS:
      if (millis() - startResetTime > 1000){
        currState = UPDATE_HAPTICS;
//        ledState = !ledState;
        digitalWrite(LED_BUILTIN, LOW);
      }
    break;
  }
  
}

void updateHaptics() {
//  toggleState();
  startSample = true;
  
  updateEncoderAB();
  positionVal = filterEncoderAB();
  thisForce = updateRawForce();
  Input = filterForce();
  
  updateVelocity();

  Setpoint = calculateSetpoint();
  
  if (myPID.Compute()) {
    Output -= dxh_filt * Kd_vel;
    offsetOutput(800.0, 4096.0);  
    
    pwmVal0 = (abs(Output) + Output) / 2;
    pwmVal1 = (abs(Output) - Output) / 2;
    analogWrite(pwmPin0, pwmVal0);
    analogWrite(pwmPin1, pwmVal1);
  }
  
  printVals();
//  if (Serial.available()) {
//    cmdProcessing = Serial.read();
//    Serial.println(cmdProcessing);
//  }
//  if (cmdProcessing != '0') {
//    currState = WAIT_FOR_CMD;
//  }
}

float filterForce() {
  ffWindow[ffIndex] = thisForce;
  float ffFilt = averageBuf(ffWindow, ffWindowSize);
  ffIndex++;
  ffIndex %= ffWindowSize;
  return ffFilt;
}

void updateVelocity() {
  currVelUpdate = millis();
  if (currVelUpdate - lastVelUpdate > velTime) {
    xh = Input_pos;
    dxh = (double)(xh - xh_prev);
    // Calculate the filtered velocity of the handle using an infinite impulse response filter
    dxh_filt = .85*dxh + 0.1*dxh_prev + 0.05 * dxh_prev2; 
    
    xh_prev2 = xh_prev;
    xh_prev = xh;
    
    dxh_prev2 = dxh_prev;
    dxh_prev = dxh;
    
    dxh_filt_prev2 = dxh_filt_prev;
    dxh_filt_prev = dxh_filt;
    
    lastVelUpdate = currVelUpdate;
  }
  
}

void printVals() {
    currPrintTime = millis();
    if (currPrintTime - lastPrintTime > 5*printTimeInterval) {
      Serial.print(positionVal);
      Serial.println();
      lastPrintTime = currPrintTime;
    }
}
