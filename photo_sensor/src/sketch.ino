/*
 * Simple sketch to test a light sensor
 */
 
int led = 13;
int statusLed = 7;
int lightPin = 2;

void setup() {                
  Serial.begin(9600);  
  // initialize the digital pin as an output.
  pinMode(led, OUTPUT);     
  digitalWrite(led, HIGH);
  
  pinMode(statusLed, OUTPUT);
}

void loop() {
  if (digitalRead(lightPin) == HIGH) {
    digitalWrite(statusLed, LOW);
    Serial.println("Tripped");
  } else {
    digitalWrite(statusLed, HIGH);
  }
  delay(100);
}