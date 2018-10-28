// hue_bulb
// Dan Berman
// 10/28/2018
// Code to run the 'philips hue' demo bulb
// Uses Serial @ 9600 baud
// Receives 4 values - RGB (0-255) + brightness (0-100), with each value separated by a non-numeric character,
// preceded by 'c'.[
// Sending 'r' will toggle on rainbow mode

#include <Adafruit_NeoPixel.h>

#define PIN 6
#define PIXELS 5

// Parameter 1 = number of pixels in strip
// Parameter 2 = Arduino pin number (most are valid)
// Parameter 3 = pixel type flags, add together as needed:
//   NEO_KHZ800  800 KHz bitstream (most NeoPixel products w/WS2812 LEDs)
//   NEO_KHZ400  400 KHz (classic 'v1' (not v2) FLORA pixels, WS2811 drivers)
//   NEO_GRB     Pixels are wired for GRB bitstream (most NeoPixel products)
//   NEO_RGB     Pixels are wired for RGB bitstream (v1 FLORA pixels, not v2)
//   NEO_RGBW    Pixels are wired for RGBW bitstream (NeoPixel RGBW products)
Adafruit_NeoPixel strip = Adafruit_NeoPixel(PIXELS, PIN, NEO_GRB + NEO_KHZ800);

Adafruit_NeoPixel startup = Adafruit_NeoPixel(1, 5, NEO_GRB + NEO_KHZ800); // Single LED to indicate startup status
// Only used during setup()

bool on;
int brightness;
int red;
int green;
int blue;

void setup() {

  red = 0;
  green = 0;
  blue = 0;
  brightness = 0;
  on = false;

  strip.begin();
  strip.show();

  startup.begin();
  startup.show();

  Serial.begin(9600);
  while (!Serial);

  // Wait to receive from bluetooth indicating connected, blink red to indicate waiting
  bool toggledOn = false;

  while (true) {
    if (Serial.available() > 0)
    {
      Serial.read(); // Clear buffer
      break;
    }

    if (toggledOn)
    {
      startup.setPixelColor(0, 0, 0, 0); // Turn LED off
    } else
    {
      startup.setPixelColor(0, 255, 0, 0); // Turn LED red
    }

    toggledOn = !toggledOn;
    delay(250);

  }

  // Bluetooth connected, flash green 3x, then solid green to indicate connected
  for (int i = 0; i < 3; i++)
  {
    startup.setPixelColor(0, 0, 0, 0);
    delay(500);
    startup.setPixelColor(0, 0, 255, 0);
    delay(500);
  }

}

void loop() {

  if (Serial.available() > 0)
  {
    char cmd = Serial.read();

    switch (cmd) {

      case 'b':
        brightness = Serial.parseInt();

        setColor();

        Serial.read(); // Clear the buffer
        break;

      case 'c':
        red = Serial.parseInt();
        green = Serial.parseInt();
        blue = Serial.parseInt();

        setColor();

        Serial.read(); // Clear the buffer
        break;

      case 'o':
        on = !on;
        setColor();
        break;

      case 'r':
        rainbowScroll(5);
        break;

      default:
        break;
    }
  }

}

// Fill the dots one after the other with a color
void setColor()
{
  if (on)
  {
    // Adjust color levels by brightness
    int r = red * brightness / 100;
    int g = green * brightness / 100;
    int b = blue * brightness / 100;
  } else
  {
    int r = 0;
    int g = 0;
    int b = 0;
  }

  // Push the color out to all pixels
  for (int i = 0; i < strip.numPixels(); i++)
  {
    strip.setPixelColor(i, r, g, b);
  }

  strip.show();
}

void rainbowScroll(uint8_t wait) {
  uint32_t wheelVal;
  int redVal, greenVal, blueVal;

  bool rainbow = true;

  while (rainbow)
  {

    for (int j = 0; j < 256; j++) // 5 cycles of all colors on wheel
    { 

      wheelVal = Wheel(j & 255);

      redVal = redT(wheelVal);
      greenVal = greenT(wheelVal);
      blueVal = blueT(wheelVal);

      if (on)
      {
        for (int i = 0; i < strip.numPixels(); i++)
        {
          strip.setPixelColor( i, strip.Color( redVal, greenVal, blueVal ) );
        }
      }

      strip.show();
      delay(wait);

      if (Serial.available() > 0)
      {
        char cmd = Serial.read();
        if (cmd == 'r')
        {
          rainbow = false;
          break;
        }
      }
    }

  }

}

// Input a value 0 to 255 to get a color value.
// The colours are a transition r - g - b - back to r.
uint32_t Wheel(byte WheelPos) {
  WheelPos = 255 - WheelPos;
  if (WheelPos < 85) {
    return strip.Color(255 - WheelPos * 3, 0, WheelPos * 3, 0);
  }
  if (WheelPos < 170) {
    WheelPos -= 85;
    return strip.Color(0, WheelPos * 3, 255 - WheelPos * 3, 0);
  }
  WheelPos -= 170;
  return strip.Color(WheelPos * 3, 255 - WheelPos * 3, 0, 0);
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
