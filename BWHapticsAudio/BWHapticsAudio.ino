
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
}


void loop() {
  
  toggleState();
  
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
    if (currPrintTime - lastPrintTime > printTimeInterval) {
      Serial.print(Setpoint);
//      Serial.print(", ");
//      Serial.print(dxh_filt*100.0);
//      Serial.print(", ");
//      Serial.print(dataCount);
      Serial.print(", ");
      Serial.print(Input);
      Serial.println();
      lastPrintTime = currPrintTime;
    }
}
