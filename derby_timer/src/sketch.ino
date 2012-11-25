/*
 * car_timer_3c
 *
 * Time the race between to items (cars) using polling.
 * Track 3 separate cars (or what ever event your are timing).
 * Output is sent to the serial port.
 *
 * 
 * This sketch supports:
 *   3 IR LEDs & Sensors (one pair per track)
 *   Start switch
 *   Servo to open the starting gate
 *   Reset switch to zero the timing registers
 *   Track times are output to the serial port.
 *   Reset and start commands can be triggered by serial port.
 *
 * I have source code available for a Mac client that works with 
 * this sketch. Email me if you are interested - will@wgmamm.com
 *
 * Written by Damien Stuart and Will McCracken <will@wgmamm.com>
 * Copyright 2012
*/

#include <stdio.h>
#include <Servo.h>

#define READY    0
#define RACING   1
#define FINISHED 2

#define SERVOSTART 1
#define SERVOEND   160

const int resetPin = 4;
const int startPin = 8;
const int carPin1 = 5;
const int carPin2 = 6;
const int carPin3 = 7;
const int servoPin = 9;

int servoPos = SERVOSTART;
Servo starterServo;

int incomingByte = 0;

int state;
unsigned long startMillis;

struct cStats {
  unsigned long time;
  boolean gotInterrupt;
  boolean finished;
};

volatile struct cStats cs[3];

void stat_print(void)
{
  int i, secs, frac;
  unsigned long intval;
  char buf[80] = {0};
  
  for(i=0; i<3; i++)
  {
    intval = cs[i].time - startMillis;
    secs = floor(intval/1000);
    frac = intval - (secs*1000);
    sprintf(buf, "%i:%i.%03i|", i+1, secs, frac);
    Serial.print(buf);
  }

}

void initStats(void)
{
  startMillis = 0;
  cs[0].gotInterrupt = cs[0].finished = false;
  cs[1].gotInterrupt = cs[1].finished = false;
  cs[2].gotInterrupt = cs[2].finished = false;
  char buf[80] = {0};
  sprintf(buf,"1:0.000|2:0.000|3:0.000|");
  Serial.print(buf);
}

void setup() 
{
  // Initialize the LCD
  //
  Serial.begin(19200);
  
  // attach the servo
  starterServo.attach(servoPin);
  starterServo.write(SERVOSTART);
  
  pinMode(resetPin, INPUT);
  pinMode(startPin, INPUT);
  
  initStats();
  
  state = READY;
  delay(50);
}

// Main loop...
//
void loop()
{  
  // first check for serial instructions
  if (Serial.available() > 0) {
    // read the incoming byte:
    incomingByte = Serial.read();
    if (incomingByte == 49) {
      initStats();
      state = READY;
    } else if (incomingByte == 54 && state == READY) {
      if (starterServo.attached()) {
        starterServo.write(SERVOEND);
        startMillis = millis();
        state = RACING;
      } 
    }
  } else {
    incomingByte = -1;
  }
  
  if(state == RACING)
  {
    
    // Check the car pins.
    //
    if(! cs[0].finished && digitalRead(carPin1) == LOW)
    {
      cs[0].time = millis();
      cs[0].finished = true;
    }

    if(! cs[1].finished && digitalRead(carPin2) == LOW)
    {
      cs[1].time = millis();
      cs[1].finished = true;
    }

    if(! cs[2].finished && digitalRead(carPin3) == LOW)
    {
      cs[2].time = millis();
      cs[2].finished = true;
    }
    
    if(! cs[0].finished)
      cs[0].time = millis();
    if(! cs[1].finished)
      cs[1].time = millis();
    if(! cs[2].finished)
      cs[2].time = millis();
      
    stat_print();
     
    if(cs[0].finished && cs[1].finished && cs[2].finished)
    {
      state = FINISHED;
      if (starterServo.attached())
        starterServo.write(SERVOSTART);
    }
  }
  else if(state == READY)
  {
    // Check for start triggered...
    //
    if(digitalRead(startPin) == HIGH)
    {
      startMillis = millis();
      state = RACING;
    }
  }
  else if(state == FINISHED)
  {
    // Check for reset...
    //
    if(digitalRead(resetPin) == HIGH)
    {
      initStats();
      state = READY;
    }
  }
}
