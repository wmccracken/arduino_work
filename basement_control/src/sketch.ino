#include <stdio.h>
#include <softwareserial.h>

const int ping_sensor_pin = 7;
const int serial_speed = 9600;
const int poll_interval = 10000;
SoftwareSerial impSerial(8, 9); // RX on 8, TX on 9 for imp

float current_temperature = 22.2222; // in C

void setup()
{
  Serial.begin(9600);
  // set the data rate for the SoftwareSerial port
  // impSerial.begin(19200);
}

void loop()
{
  // establish variables for duration of the ping, 
  // and the distance result in inches and centimeters:
  float duration, inches, cm;

  // The PING))) is triggered by a HIGH pulse of 2 or more microseconds.
  // Give a short LOW pulse beforehand to ensure a clean HIGH pulse:
  pinMode(ping_sensor_pin, OUTPUT);
  digitalWrite(ping_sensor_pin, LOW);
  delayMicroseconds(2);
  digitalWrite(ping_sensor_pin, HIGH);
  delayMicroseconds(5);
  digitalWrite(ping_sensor_pin, LOW);

  // The same pin is used to read the signal from the PING))): a HIGH
  // pulse whose duration is the time (in microseconds) from the sending
  // of the ping to the reception of its echo off of an object.
  pinMode(ping_sensor_pin, INPUT);
  duration = pulseIn(ping_sensor_pin, HIGH);

  // convert the time into a distance
  inches = microseconds_to_inches(duration);
  cm = microseconds_to_centimeters(duration);
  
  Serial.print(inches);
  Serial.print("in, ");
  Serial.print(cm);
  Serial.print("cm");
  Serial.println();
  
  delay(poll_interval);  
}

float microseconds_to_inches(float microseconds)
{
  return microseconds / micros_per_inch() / 2;
}

float microseconds_to_centimeters(float microseconds)
{
  return microseconds / micros_per_centimeter() / 2;
}

float micros_per_centimeter()
{
  return (100/speed_of_sound()) * 100;
}

float micros_per_inch()
{
  return (speed_of_sound() * 3.28084) / 12;
}

float speed_of_sound()
{
  // the speed of sound is adjusted by air temperature
  // 331.3 m/s plus .606 * current temp in C
  return 331.3 + (0.606 * current_temperature);
}
