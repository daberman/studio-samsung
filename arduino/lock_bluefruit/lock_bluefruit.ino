/*
   lock_bluefuit.ino
   by Dan Berman
   created 12/13/18
   updated 12/13/18

   Arduino code for CT Product Studio - team 75 (Samsung). Controls the servo operating the fake smart lock.
   An optional RGB LED can be connected to the board to use
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
#include <Servo.h> // make sure to delete Documents/Arduino/Servo so correct library is used from Adafruit

/* Constants */

// DEBUG to enable Serial prints over USB @ 115200 baud
#define DEBUG 0 // Enable debug prints


// Constants for the RGB status LED
#define STATUS_LED_EN     true
#define STATUS_R_LED_PIN  31
#define STATUS_G_LED_PIN  30
#define STATUS_B_LED_PIN  27
#define LED_ON            LOW
#define LED_OFF           HIGH

// Constants for the Servo
#define SERVO_PIN 11
#define LOCK_OPEN 0
#define LOCK_SHUT 180


/* Global Variables */
BLEUart bleuart;
Servo lockServo;

void setup()
{
  // Setup USB Serial @ 115200 baud if DEBUG enabled
  if ( DEBUG )
  {
    Serial.begin(115200);
    while ( !Serial ) delay(10);

    Serial.println("Smart Lock Debug Mode Enabled");
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

  if ( DEBUG > 1) delay(1000);

  // Setup lock servo
  if ( DEBUG ) Serial.println("Initializing Servo...");
  if ( STATUS_LED_EN ) digitalWrite(STATUS_R_LED_PIN, LED_ON);

  lockServo.attach(SERVO_PIN);
  lockServo.write(LOCK_OPEN);

  if ( DEBUG > 1) delay(1000);

  // Init Bluefruit
  if ( DEBUG ) Serial.println("Initializing Bluetooth...");
  if ( STATUS_LED_EN ) digitalWrite(STATUS_B_LED_PIN, LED_ON); // Add blue to make purple!
  if ( DEBUG > 2 ) delay(1000);

  Bluefruit.begin();
  // Set max power. Accepted values are: -40, -30, -20, -16, -12, -8, -4, 0, 4
  Bluefruit.setTxPower(4);
  Bluefruit.setName("Lock_Bluefruit");
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
  if (DEBUG && Serial.available()) processCmd(&Serial);\
}

/* Process a command from a Stream */
void processCmd(Stream *s)
{
  char cmd = s->read();
  char c;

  if ( DEBUG ) Serial.println("Processing command");

  switch (cmd) {

    case 'l': // Fall Through
    case 'u':
      if (DEBUG > 2) Serial.println("Updating lock");
      updateServo(cmd);
      
      s->flush();
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

/* Smart Lock Servo Functions */
void updateServo(char cmd) {
  if (cmd == 'l') {
    lockServo.write(LOCK_SHUT);
    if ( DEBUG > 1) Serial.println("Locking...");
  } else if (cmd == 'u') {
    lockServo.write(LOCK_OPEN);
    if ( DEBUG > 1) Serial.println("Unlocking...");
  }
}
