/*  IMP Code to read RHT03 Temp & Humidity Sensor */

/*
  Developed by Will McCracken - Dec. 2012
  email me at will AT wgmamm.com

  This code is adapted from the arduino sensor library written by
  Ben Adams (nethoncho AT gmail.com).

  This library is free software; you can redistribute it and/or
  modify it under the terms of the GNU Lesser General Public
  License as published by the Free Software Foundation; either
  version 2.1 of the License, or (at your option) any later version.

  This library is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
  Lesser General Public License for more details.

  You should have received a copy of the GNU Lesser General Public
  License along with this library; if not, write to the Free Software
  Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA

  Version 0.1: 30-Dec-2012 by Will McCracken
*/

// https://www.sparkfun.com/products/10167
// this code is adapted from the arduino sensor library written by
// Ben Adams

local rht_dpin = hardware.pin7; // digital pin on imp that is connected to pin 2 on sensor

local temperatureOutput = OutputPort("Temperature", "string");
local humidityOutput = OutputPort("Humidity", "string");  
const DHT22_DATA_BIT_COUNT = 41
local myDHT22 = null;

enum DHT22_ERROR_t {
  DHT_ERROR_NONE,
  DHT_BUS_HUNG,
  DHT_ERROR_NOT_PRESENT,
  DHT_ERROR_ACK_TOO_LONG,
  DHT_ERROR_SYNC_TIMEOUT,
  DHT_ERROR_DATA_TIMEOUT,
  DHT_ERROR_CHECKSUM,
  DHT_ERROR_TOOQUICK
}

class DHT22 {
  // methods
  constructor(pin) {
    //_bitmask = digitalPinToBitMask(pin);
    //_baseReg = portInputRegister(digitalPinToPort(pin));
    _lastReadTime = clock();
    _lastHumidity = -995.0;
    _lastTemperature = -995.0;
    _pin = pin;
  }

  function getHumidityInt() {
    return _lastHumidity;
  }

  function getTemperatureCInt() {
    return _lastTemperature;
  }

  function getHumidity() {
    return _lastHumidity/10;
  }

  function getTemperatureC() {
    return _lastTemperature/10;
  }

  function getTemperatureF() {
    return (((getTemperatureC() *9 ) / 5) + 32);
  }

  function clockReset() {
    _lastReadTime = clock();
  }

  // this function does the real work - it gathers the data from the sensor
  // and stores the values
  function read_data() {
    local retryCount;
    local currentHumidity;
    local currentTemperature;
    local bitTimes = array(DHT22_DATA_BIT_COUNT, 0);
    local checkSum, csPart1, csPart2, csPart3, csPart4;
    local currentTime;
    local i;


    currentHumidity = 0;
    currentTemperature = 0;
    checkSum = 0;
    currentTime = clock();

    // caller needs to wait at least two seconds between calls
    if (currentTime - _lastReadTime < 2) {
      server.log("QUICK POLL - C: " + currentTime + " L: " + _lastReadTime + " V: " + (currentTime - _lastReadTime));
      return DHT22_ERROR_t.DHT_ERROR_TOOQUICK;
    }
    _lastReadTime = currentTime;

    // Pin needs to start HIGH, wait until it is HIGH with a timeout
    _pin.configure(DIGITAL_IN);
    retryCount = 0;
    do {
      if (retryCount > 125)
      {
        return DHT22_ERROR_t.DHT_BUS_HUNG;
      }
      retryCount++;
      imp.sleep(0.000002);
    } while(!_pin.read());

    // Send the activate pulse
    _pin.configure(DIGITAL_OUT);
    _pin.write(0);
    imp.sleep(0.0011);
    _pin.configure(DIGITAL_IN); // set pin back to input to allow it to float

    // Find the start of the ACK Pulse
    retryCount = 0;
    do {
      if (retryCount > 25) //(Spec is 20 to 40 us, 25*2 == 50 us)
      {
        return DHT22_ERROR_t.DHT_ERROR_NOT_PRESENT;
      }
      retryCount++;
      imp.sleep(0.000002);
    } while(!_pin.read());

    // Find the end of the ACK Pulse
    retryCount = 0;
    do {
      if (retryCount > 50) //(Spec is 80 us, 50*2 == 100 us)
      {
        return DHT22_ERROR_t.DHT_ERROR_ACK_TOO_LONG;
      }
      retryCount++;
      imp.sleep(0.000002);
    } while(_pin.read());


    // Read the 40 bit data stream
    for(i = 0; i < DHT22_DATA_BIT_COUNT; i++) {
      // Find the start of the sync pulse
      retryCount = 0;
      do {
        if (retryCount > 35) //(Spec is 50 us, 35*2 == 70 us)
        {
          return DHT22_ERROR_t.DHT_ERROR_SYNC_TIMEOUT;
        }
        retryCount++;
        imp.sleep(0.000002);
      } while(!_pin.read());

      // Measure the width of the data pulse
      retryCount = 0;
      do {
        if (retryCount > 50) //(Spec is 80 us, 50*2 == 100 us)
        {
          server.log("Got " + i + " RC: " + retryCount);
          return DHT22_ERROR_t.DHT_ERROR_DATA_TIMEOUT;
        }
        retryCount++;
        imp.sleep(0.000002);
      } while(_pin.read());
      server.log("Got " + i + " RC: " + retryCount);
      bitTimes[i] = retryCount;
    }

    return DHT22_ERROR_t.DHT_ERROR_NONE;
  }

  // properties
  _pin = null;
  _lastReadTime = null;
  _lastHumidity = null;
  _lastTemperature = null;
};


function process_readings() {
  /*
    Uses global variables rht_data[0-4], and global_error to pass
    "answer" back. global_error=0 if read went okay.
  */
  imp.wakeup(60, process_readings.bindenv(this));    // schedule the next poll in 1 min
  server.show("Requesting data...");
  local errorCode = myDHT22.read_data();
  switch(errorCode) {
    case DHT22_ERROR_t.DHT_ERROR_NONE:
      local temp = myDHT22.getTemperatureF();
      local humid = myDHT22.getHumidity();
      
      server.show(temp + "F " + humid + " %RH");
      break;
    case DHT22_ERROR_t.DHT_ERROR_CHECKSUM:
      server.show("check sum error ");
      break;
    case DHT22_ERROR_t.DHT_BUS_HUNG:
      server.show("BUS Hung");
      break;
    case DHT22_ERROR_t.DHT_ERROR_NOT_PRESENT:
      server.show("Not Present");
      break;
    case DHT22_ERROR_t.DHT_ERROR_ACK_TOO_LONG:
      server.show("ACK time out");
      break;
    case DHT22_ERROR_t.DHT_ERROR_SYNC_TIMEOUT:
      server.show("Sync Timeout");
      break;
    case DHT22_ERROR_t.DHT_ERROR_DATA_TIMEOUT:
      server.show("Data Timeout");
      break;
    case DHT22_ERROR_t.DHT_ERROR_TOOQUICK:
      server.show("Polled to quick");
      break;
  }
}

imp.configure("IMP Temperature & Humidity", [], [temperatureOutput, humidityOutput]);
server.show("Starting Up..");
myDHT22 = DHT22(rht_dpin);
imp.sleep(3);
process_readings();
// The end