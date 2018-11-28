#include <Servo.h> 
#include <Adafruit_NeoPixel.h>

#define PIN 4
#define PIXELS 5

Servo myservo;
Adafruit_NeoPixel strip = Adafruit_NeoPixel(PIXELS, PIN, NEO_GRB + NEO_KHZ800);

int brightness;
int red;
int green;
int blue;

void setup() {
  myservo.attach(9);
 // myservo.write(0);

  red = 255;
  green = 0;
  blue = 0;
  
  Serial.begin(9600);
  while (!Serial);
  
  strip.begin();
  strip.setPixelColor(0, red, green, blue);
  strip.setPixelColor(1, red, green, blue);
  strip.setPixelColor(2, red, green, blue);
  strip.show();

}

void loop() {
  if (Serial.available() > 0)
  {
    char cmd = Serial.read();
    if (cmd == 'l')
    {
      if (myservo.read() > 90)
      {
        myservo.write(0);
        red = 0;
        green = 255;
        blue = 0;
        strip.setPixelColor(0, red, green, blue);
        strip.show();
      }
      else if (myservo.read() <= 90)
      {
        myservo.write(180);
        red = 0;
        green = 0;
        blue = 255;
        strip.setPixelColor(0, red, green, blue);
        strip.show();
      }

      Serial.read(); // Clear the buffer
    }
   
  }
}
