int Senval=0;

int Senpin=A0;

void setup()
{
    Serial.begin(9600);
}

void loop()
{

    Senval=analogRead(Senpin);
    if (Senval > 10) {
      Serial.print("Tripped: ");
      Serial.println(Senval);
    }
}