#include <Servo.h> 
#include <Adafruit_NeoPixel.h>


#define STARTUP_PIN 4
#define STARTUP_PIXELS 3

Servo myservo;

// 3 LEDs to indicate startup status. Only used during setup()
Adafruit_NeoPixel startup = Adafruit_NeoPixel(STARTUP_PIXELS, STARTUP_PIN, NEO_GRB + NEO_KHZ800);  

int brightness;
int red;
int green;
int blue;

void setup() {

  startup.begin();
  startup.show();

  //startup.setPixelColor(0, 255, 0, 0);
  //startup.show();
  
  myservo.attach(9);
 // myservo.write(0);

//  startup.setPixelColor(1, 255, 0, 0);
//  startup.show();
  
  Serial.begin(9600);
  while (!Serial);    
  
  // Wait to receive from bluetooth indicating connected, blink red to indicate waiting
//  bool toggledOn = false;
//
//  while (true) {
//    if (Serial.available() > 0)
//    {
//      Serial.read(); // Clear buffer
//      break;
//    }
//
//    if (toggledOn)
//    {
//      startup.setPixelColor(2, 0, 0, 0); // Turn LED off
//    } else
//    {
//      startup.setPixelColor(2, 255, 0, 0); // Turn LED red
//    }
//    startup.show();
//    
//    toggledOn = !toggledOn;
//    delay(250);
//
//  }

  for (int i = 0; i < STARTUP_PIXELS; i++)
  {
    startup.setPixelColor(i, 0, 0, 255);
  }
  startup.show();
  


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
        for (int i = 0; i < STARTUP_PIXELS; i++)
        {
          startup.setPixelColor(i, 0, 255, 0);
        }
        startup.show();
      }
      else if (myservo.read() <= 90)
      {
        myservo.write(180); 
        for (int i = 0; i < STARTUP_PIXELS; i++)
        {
          startup.setPixelColor(i, 255, 0, 0);
        }
        startup.show();
      }

      Serial.read(); // Clear the buffer
    }
   
  }
}
