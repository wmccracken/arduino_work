#include <DHT22.h>
// Only used for sprintf
#include <stdio.h>

#include <softwareserial.h>

SoftwareSerial impSerial(8, 9); // RX on 8, TX on 9

// Data wire is plugged into port 7 on the Arduino
// Connect a 4.7K resistor between VCC and the data pin (strong pullup)
#define DHT22_PIN 4

// Setup a DHT22 instance
DHT22 myDHT22(DHT22_PIN);

void setup(void)
{
  // start serial port
  Serial.begin(19200);
  
  // set the data rate for the SoftwareSerial port
  impSerial.begin(19200);

  Serial.println("Temp / Humidity Sensor Starting Up.");
  delay(4000);
}

void loop(void)
{ 
  DHT22_ERROR_t errorCode;
  float temp;
  float humid;
  
  // The sensor can only be read from every 1-2s, and requires a minimum
  // 2s warm-up after power-on.
  delay(300000);
  
  Serial.print("Requesting data...");
  errorCode = myDHT22.readData();
  switch(errorCode)
  {
    case DHT_ERROR_NONE:
      temp = ((myDHT22.getTemperatureC() *9 ) / 5) + 32;
      humid = myDHT22.getHumidity();
      Serial.print("Got Data ");
      Serial.print(temp);
      Serial.print("F ");
      Serial.print(humid);
      Serial.println("% RH");

      char buf1[7];
      char buf2[7];
      dtostrf(temp,6,2,buf1);
      dtostrf(humid,6,2,buf2);
      impSerial.print("[");
      impSerial.write(buf1);
      impSerial.print("]");
      impSerial.write(buf2);
      impSerial.println("");
      // Alternately, with integer formatting which is clumsier but more compact to store and
	  // can be compared reliably for equality:
	  // //	  
   //    char buf[128];
   //    sprintf(buf, "Integer-only reading: Temperature %hi.%01hi C, Humidity %i.%01i %% RH",
   //                 myDHT22.getTemperatureCInt()/10, abs(myDHT22.getTemperatureCInt()%10),
   //                 myDHT22.getHumidityInt()/10, myDHT22.getHumidityInt()%10);
   //    Serial.println(buf);
      break;
    case DHT_ERROR_CHECKSUM:
      Serial.print("check sum error ");
      Serial.print(myDHT22.getTemperatureC());
      Serial.print("C ");
      Serial.print(myDHT22.getHumidity());
      Serial.println("%");
      break;
    case DHT_BUS_HUNG:
      Serial.println("BUS Hung ");
      break;
    case DHT_ERROR_NOT_PRESENT:
      Serial.println("Not Present ");
      break;
    case DHT_ERROR_ACK_TOO_LONG:
      Serial.println("ACK time out ");
      break;
    case DHT_ERROR_SYNC_TIMEOUT:
      Serial.println("Sync Timeout ");
      break;
    case DHT_ERROR_DATA_TIMEOUT:
      Serial.println("Data Timeout ");
      break;
    case DHT_ERROR_TOOQUICK:
      Serial.println("Polled to quick ");
      break;
  }
}