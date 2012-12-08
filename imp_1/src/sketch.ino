#include <softwareserial.h>

SoftwareSerial impSerial(8, 9); // RX on 8, TX on 9

void setup()  
{
 // Open the hardware serial port
  Serial.begin(19200);
  
  // set the data rate for the SoftwareSerial port
  impSerial.begin(19200);
}

void loop() // run over and over
{  
  // Send data from the software serial
  if (impSerial.available())
    Serial.write(impSerial.read());  // to the hardware serial
  // Send data from the hardware serial
  if (Serial.available())
    impSerial.write(Serial.read());  // to the software serial
}
