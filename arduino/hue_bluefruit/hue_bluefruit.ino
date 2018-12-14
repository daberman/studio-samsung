/*
   hue_bluefuit.ino
   by Dan Berman
   created 12/4/18
   updated 12/13/18

   Arduino code for CT Product Studio - team 75 (Samsung). Controls the mock Philips Hue lightbulb.
   Requires the Adafruit_NeoPixel library. An optional RGB LED can be connected to the board to use
   as a startup status indicator.

   This code is written to be used on an Adafruit nRF52 Bluefruit Feather board
   (https://www.adafruit.com/product/3406)

   User guide located at: https://learn.adafruit.com/bluefruit-nrf52-feather-learning-guide/introduction
   GitHub Repo: https://github.com/adafruit/Adafruit_nRF52_Arduino

   BSP Installation (necessary):
    - Add https://www.adafruit.com/package_adafruit_index.json as an 'Additional Board Manager URL'
      (Arduino -> Preferences -> Settings)
    - Install 'Adafruit nRF52 by Adafruit' from Tools -> Board -> Boards Manager
    - Select Tools -> Board -> "Adafruit Bluefruit nRF52832 Feather"
    - Ensure Tools -> Programmer is set to "Bootloader DFU for Bluefruit nRF52"

   CP2104 Driver (necessary if not previously installed for a different board):
     - https://www.silabs.com/products/development-tools/software/usb-to-uart-bridge-vcp-drivers
     - Select Tools -> Port -> SLAB_USBtoUART (or similar)

   Bootloader Update (try if getting a timeout error when uploading to board):
    - Tools -> Burn Bootloader
*/

#include <bluefruit.h>
#include <Adafruit_NeoPixel.h>


/* Constants */

// DEBUG to enable Serial prints over USB @ 115200 baud
#define DEBUG 0 // Enable debug prints


// Constants for the RGB status LED
#define STATUS_LED_EN     true
#define STATUS_R_LED_PIN  A5 // 5
#define STATUS_G_LED_PIN  A4 // 28
#define STATUS_B_LED_PIN  A3 // 29
#define LED_ON            LOW
#define LED_OFF           HIGH

// Constants for the NeoPixels
#define BULB_PIN    27
#define BULB_PIXELS 4


/* Global Variables */

// Parameter 1 = number of pixels in strip
// Parameter 2 = Arduino pin number (most are valid)
// Parameter 3 = pixel type flags, add together as needed:
//   NEO_KHZ800  800 KHz bitstream (most NeoPixel products w/WS2812 LEDs)
//   NEO_KHZ400  400 KHz (classic 'v1' (not v2) FLORA pixels, WS2811 drivers)
//   NEO_GRB     Pixels are wired for GRB bitstream (most NeoPixel products)
//   NEO_RGB     Pixels are wired for RGB bitstream (v1 FLORA pixels, not v2)
//   NEO_RGBW    Pixels are wired for RGBW bitstream (NeoPixel RGBW products)
Adafruit_NeoPixel bulb = Adafruit_NeoPixel(BULB_PIXELS, BULB_PIN, NEO_GRB + NEO_KHZ800);

bool on;
bool enRainbow;
int brightness;
int red;
int green;
int blue;

BLEUart bleuart;

void setup()
{
  // Setup USB Serial @ 115200 baud if DEBUG enabled
  if ( DEBUG )
  {
    Serial.begin(115200);
    while ( !Serial ) delay(10);

    Serial.println("Hue Bulb Debug Mode Enabled");
    Serial.println("---------------------------");

    Serial.println();
  }

  if ( DEBUG > 1 ) delay(1000);

  // Setup status LED
  if ( STATUS_LED_EN )
  {
    if ( DEBUG ) Serial.println("Status LED enabled. Initializing...");

    pinMode(STATUS_R_LED_PIN, OUTPUT);
    pinMode(STATUS_G_LED_PIN, OUTPUT);
    pinMode(STATUS_B_LED_PIN, OUTPUT);
    digitalWrite(STATUS_R_LED_PIN, LED_OFF);
    digitalWrite(STATUS_G_LED_PIN, LED_OFF);
    digitalWrite(STATUS_B_LED_PIN, LED_OFF);
  }

  if ( DEBUG > 1 ) delay(1000);

  // Setup NeoPixels for the bulb
  if ( DEBUG ) Serial.println("Initializing NeoPixels...");
  if ( STATUS_LED_EN ) digitalWrite(STATUS_R_LED_PIN, LED_ON); // Turn on red

  red = 255;
  green = 255;
  blue = 255;
  brightness = 100;
  on = false;
  enRainbow = false;

  bulb.begin();
  setColor();
  bulb.show();

  if ( DEBUG > 1) delay(1000);

  // Init Bluefruit
  if ( DEBUG ) Serial.println("Initializing Bluetooth...");
  if ( STATUS_LED_EN ) digitalWrite(STATUS_B_LED_PIN, LED_ON); // Add blue to make purple!
  if ( DEBUG > 2 ) delay(1000);

  Bluefruit.begin();
  // Set max power. Accepted values are: -40, -30, -20, -16, -12, -8, -4, 0, 4
  Bluefruit.setTxPower(4);
  Bluefruit.setName("Hue_Bluefruit");
  Bluefruit.setConnectCallback(connect_callback);
  Bluefruit.setDisconnectCallback(disconnect_callback);

  bleuart.setRxCallback(bleuart_callback);
  bleuart.begin(); // Configure and start the BLE Uart service

  startAdv(); // Set up and start advertising

  if ( DEBUG ) Serial.println("Bluetooth Initialization complete");
  if ( STATUS_LED_EN ) digitalWrite(STATUS_R_LED_PIN, LED_OFF); // Turn off red
}

/* Main loop */
void loop()
{
  if (DEBUG && Serial.available()) processCmd(&Serial);
  if (on && enRainbow) rainbowScroll(10);
}

/* Process a command from a Stream */
void processCmd(Stream *s)
{
  char cmd = s->read();
  char c;

  if ( DEBUG ) Serial.println("Processing command");

  switch (cmd) {

    case 'b': // Update brightness
      if (DEBUG > 2) Serial.println("Updating brightness");
      brightness = s->read();

      setColor();

      s->flush(); // Clear the buffer
      break;

    case 'c': // Update color
      if (DEBUG > 2) Serial.println("Updating color");
      red = s->read();
      green = s->read();
      blue = s->read();

      setColor();

      s->flush(); // Clear the buffer
      break;

    case 'o': // Set On/Off
      if (DEBUG > 2) Serial.println("On/Off command received");
      c = s->read();
      if (c == 'n') {
        on = true;
      }
      else if (c == 'f') {
        on = false;
      }
      setColor();

      s->flush(); // Clear the buffer
      break;

    case 'r': // Control Rainbow mode
      if (DEBUG > 2) Serial.println("Rainbow command received");
      s->read(); // Skip next character
      c = s->read();
      if (c == 'n') {
        enRainbow = true;
      }
      else if (c == 'f') {
        enRainbow = false;
      }
      
      s->flush(); // Clear the buffer
      break;

    case 'P': // Debug print what is being sent over bluetooth to Serial
      if (DEBUG > 2) Serial.print("Received via bluetooth: ");
      if ( DEBUG ) debugBLEUart();
      break;

    default:
      break;
  } // End switch
} // End processCmd()

/* Bluefruit Functions */
void startAdv(void)
{
  // Advertising packet
  Bluefruit.Advertising.addFlags(BLE_GAP_ADV_FLAGS_LE_ONLY_GENERAL_DISC_MODE);
  Bluefruit.Advertising.addTxPower();

  // Include bleuart 128-bit uuid
  Bluefruit.Advertising.addService(bleuart);

  // Secondary Scan Response packet (optional)
  // Since there is no room for 'Name' in Advertising packet
  Bluefruit.ScanResponse.addName();

  /* Start Advertising
     - Enable auto advertising if disconnected
     - Interval:  fast mode = 20 ms, slow mode = 152.5 ms
     - Timeout for fast mode is 30 seconds
     - Start(timeout) with timeout = 0 will advertise forever (until connected)

     For recommended advertising interval
     https://developer.apple.com/library/content/qa/qa1931/_index.html
  */
  Bluefruit.Advertising.restartOnDisconnect(true);
  Bluefruit.Advertising.setInterval(32, 244);    // in unit of 0.625 ms
  Bluefruit.Advertising.setFastTimeout(30);      // number of seconds in fast mode
  Bluefruit.Advertising.start(0);                // 0 = Don't stop advertising after n seconds
}

void connect_callback(uint16_t conn_handle)
{
  char central_name[32] = { 0 };
  Bluefruit.Gap.getPeerName(conn_handle, central_name, sizeof(central_name));

  if ( DEBUG )
  {
    Serial.print("Connected to ");
    Serial.println(central_name);
  }
  if ( STATUS_LED_EN )
  {
    digitalWrite(STATUS_R_LED_PIN, LED_OFF);
    digitalWrite(STATUS_G_LED_PIN, LED_ON);
    digitalWrite(STATUS_B_LED_PIN, LED_OFF);
  }
}

void disconnect_callback(uint16_t conn_handle, uint8_t reason)
{
  if ( DEBUG ) Serial.println("Bluetooth disconnected");
  if ( STATUS_LED_EN )
  {
    digitalWrite(STATUS_R_LED_PIN, LED_OFF);
    digitalWrite(STATUS_G_LED_PIN, LED_OFF);
    digitalWrite(STATUS_B_LED_PIN, LED_ON);
  }
}

void bleuart_callback()
{
  processCmd(&bleuart);
}

void debugBLEUart()
{
  while (bleuart.available())
  {
    delay(2);
    uint8_t buf[64];
    int count = bleuart.readBytes(buf, sizeof(buf));
    Serial.write(buf, count);
  }
}

/* NeoPixel Functions */

// Fill the dots one after the other with a color
void setColor()
{
  int r = 0;
  int g = 0;
  int b = 0;

  if (on)
  {
    // Adjust color levels by brightness
    r = red * brightness / 100;
    g = green * brightness / 100;
    b = blue * brightness / 100;
  }

  // Push the color out to all pixels
  for (int i = 0; i < bulb.numPixels(); i++)
  {
    bulb.setPixelColor(i, r, g, b);
  }

  bulb.show();
}

void rainbowScroll(uint8_t wait) {
  uint32_t wheelVal;
  int redVal, greenVal, blueVal;

  while (on && enRainbow)
  {

    for (int j = 0; j < 256; j++) // 5 cycles of all colors on wheel
    {

      wheelVal = Wheel(j & 255);

      redVal = redT(wheelVal) * brightness/100;
      greenVal = greenT(wheelVal) * brightness/100;
      blueVal = blueT(wheelVal) * brightness/100;

      for (int i = 0; i < bulb.numPixels(); i++)
      {
        bulb.setPixelColor( i, bulb.Color( redVal, greenVal, blueVal ) );
      }

      bulb.show();
      delay(wait);

      if (!on || ! enRainbow) break;
    } // End for

  } // End while(rainbow)
  
  setColor(); // Call to return bulb to prior/current settings
  
} // end rainbowScroll()

// Input a value 0 to 255 to get a color value.
// The colours are a transition r - g - b - back to r.
uint32_t Wheel(byte WheelPos) {
  WheelPos = 255 - WheelPos;
  if (WheelPos < 85) {
    return bulb.Color(255 - WheelPos * 3, 0, WheelPos * 3, 0);
  }
  if (WheelPos < 170) {
    WheelPos -= 85;
    return bulb.Color(0, WheelPos * 3, 255 - WheelPos * 3, 0);
  }
  WheelPos -= 170;
  return bulb.Color(WheelPos * 3, 255 - WheelPos * 3, 0, 0);
}

uint8_t redT(uint32_t c) {
  return (c >> 16);
}
uint8_t greenT(uint32_t c) {
  return (c >> 8);
}
uint8_t blueT(uint32_t c) {
  return (c);
}
