#include <stdio.h>
#include <softwareserial.h>
#include <math.h>

const int ping_sensor_pin = 7;
const int thermistor_pin = 5;
const int serial_speed = 9600;
const int poll_interval = 10000;
const float vcc = 4.14; // only used for display purposes, if used
                        // set to the measured Vcc.
const float pad = 9850; // balance/pad resistor value, set this to
                        // the measured resistance of your pad resistor
const float thermr = 10000;     // thermistor nominal resistance
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

  current_temperature = read_thermistor(analogRead(thermistor_pin));
  Serial.print("Current Temp: ");
  Serial.print(current_temperature);
  Serial.println("C");

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

float read_thermistor(int RawADC) {
  long Resistance;  
  float Temp;  // Dual-Purpose variable to save space.

  Resistance=((1024 * pad / RawADC) - pad); 
  Temp = log(Resistance); // Saving the Log(resistance) so not to calculate  it 4 times later
  Temp = 1 / (0.001129148 + (0.000234125 * Temp) + (0.0000000876741 * Temp * Temp * Temp));
  Temp = Temp - 273.15;  // Convert Kelvin to Celsius                      

  // BEGIN- Remove these lines for the function not to display anything
  Serial.print("ADC: "); 
  Serial.print(RawADC); 
  Serial.print("/1024");                           // Print out RAW ADC Number
  Serial.print(", vcc: ");
  Serial.print(vcc,2);
  Serial.print(", pad: ");
  Serial.print(pad/1000,3);
  Serial.print(" Kohms, Volts: "); 
  Serial.print(((RawADC*vcc)/1024.0),3);   
  Serial.print(", Resistance: "); 
  Serial.print(Resistance);
  Serial.println(" ohms");
  // END- Remove these lines for the function not to display anything

  // Uncomment this line for the function to return Fahrenheit instead.
  //temp = (Temp * 9.0)/ 5.0 + 32.0;                  // Convert to Fahrenheit
  return Temp;
}
