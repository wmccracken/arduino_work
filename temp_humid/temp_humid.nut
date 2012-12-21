// First Floor Temp & Humidity Sensor
local rxLEDToggle = 1;  // These variables keep track of rx/tx LED toggling status
local txLEDToggle = 1;

local temperatureOutput = OutputPort("Temperature", "string");
local humidityOutput = OutputPort("Humidity", "string");  

function initUart()
{
    hardware.configure(UART_57);    // Using UART on pins 5 and 7
    hardware.uart57.configure(19200, 8, PARITY_NONE, 1, NO_CTSRTS); // 19200 baud worked well, no parity, 1 stop bit, 8 data bits
}

function initLEDs()
{
    // LEDs are on pins 8 and 9 on the imp Shield
    // They're both active low, so writing the pin a 1 will turn the LED off
    hardware.pin8.configure(DIGITAL_OUT_OD_PULLUP);
    hardware.pin9.configure(DIGITAL_OUT_OD_PULLUP);
    hardware.pin8.write(1);
    hardware.pin9.write(1);
}

// This function turns an LED on/off quickly on pin 9.
// It first turns the LED on, then calls itself again in 50ms to turn the LED off
function toggleTxLED()
{
    txLEDToggle = txLEDToggle?0:1;    // toggle the txLEDtoggle variable
    if (!txLEDToggle)
    {
        imp.wakeup(0.05, toggleTxLED.bindenv(this)); // if we're turning the LED on, set a timer to call this function again (to turn the LED off)
    }
    hardware.pin9.write(txLEDToggle);  // TX LED is on pin 8 (active-low)
}

// This function turns an LED on/off quickly on pin 8.
// It first turns the LED on, then calls itself again in 50ms to turn the LED off
function toggleRxLED()
{
    rxLEDToggle = rxLEDToggle?0:1;    // toggle the rxLEDtoggle variable
    if (!rxLEDToggle)
    {
        imp.wakeup(0.05, toggleRxLED.bindenv(this)); // if we're turning the LED on, set a timer to call this function again (to turn the LED off)
    }
    hardware.pin8.write(rxLEDToggle);   // RX LED is on pin 8 (active-low)
}

// This is our UART polling function. We'll call it once at the beginning of the program,
// then it calls itself every 10us. If there is data in the UART57 buffer, this will read
// as much of it as it can, and send it out of the impee's outputPort.
local temp = blob(6);
local humidity = blob(6);
local read_to = 0; // 0 is temp, 1 is humidity
function pollUart()
{
    imp.wakeup(0.01, pollUart.bindenv(this));    // schedule the next poll in 10us
    local byte = hardware.uart57.read();    // read the UART buffer
    // This will return -1 if there is no data to be read.
    while (byte != -1)  // otherwise, we keep reading until there is no data to be read.
    {
        switch(byte) {
            case 0x20: // ignore space
                break;
            case 0x5B: // [ signifies start of temp
                read_to = 0;
                break;
            case 0x5D: // ] signifies start of humidity
                read_to = 1;
                break;
            case 0x0A: // transmit complete
                send_values();
                temp.seek(0);
                humidity.seek(0);
                read_to = 0;
                break;
            default:
                if (byte > 45 && byte < 58) {
                    if (read_to) {
                        humidity.writen(byte,'b');
                    } else {
                        temp.writen(byte,'b');
                    }
                }
                break;
        }
//        impeeOutput.set(byte);  // send the valid character out the impee's outputPort
        byte = hardware.uart57.read();  // read from the UART buffer again (not sure if it's a valid character yet)
        toggleTxLED();  // Toggle the TX LED
    }
    
}

function send_values(){
    temperatureOutput.set(temp);
    humidityOutput.set(humidity);
//    server.show("Temp: " + temp + " RH: " + humidity); 
    server.show(blob_to_s(temp) + "F " + blob_to_s(humidity) + "%RH");
}

function blob_to_s(b){
    local out = "";
    b.seek(0);
    while(!b.eos()) {
        out += b.readn('b').tochar();  //convert the blob to string (painful, must be a better way)
    }
    return out;
}


imp.configure("TemperatureHumidity1", [], [temperatureOutput, humidityOutput]);
initUart(); // Initialize the UART, called just once
initLEDs(); // Initialize the LEDs, called just once
pollUart(); // start the UART polling, this function continues to call itself
// The end