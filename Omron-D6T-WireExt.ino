// Omron-D6T-WireExt.ino
// D6T-44L data serial port transmitter. 
// This program waits for a string in serial port for then transmits temperature 
// data, also via serial port. 
// The communication with processing program (omron_d6t_viewer) is serial port.
// Author: Bruno Silva Pontes - brunospontes@hotmail.com
// Beginning of development: April 2016

/* Tips: 
 * Arduino serial buffer length is 64 bytes. (Source: www.arduino.cc/en/Serial/Available)
 * 
 */

#include <WireExt.h>
#include <Wire.h>

#define D6T_addr 0x0A
#define D6T_cmd 0x4C

int rbuf[35];
float tdata[16];
float t_PTAT;


void setup()
{
  Wire.begin();
  Serial.begin(9600);
  Serial.flush();
}

void loop()
{
  int i;
  if (Serial.available() > 0) { // When processing requests new measurements
        int inByte = Serial.read();     // Read the received data
        if (inByte == 0x0001) {         // When was the data sent is 0x01
            Wire.beginTransmission(D6T_addr);
            Wire.write(D6T_cmd);
            Wire.endTransmission();
        
            if (WireExt.beginReception(D6T_addr) >= 0) {
              i = 0;
              for (i = 0; i < 35; i++) {
                rbuf[i] = WireExt.get_byte(); // Read temperatures from I2C
              }
              WireExt.endReception();

              // Transforming data into readable temperatures
              t_PTAT = (rbuf[0]+(rbuf[1]<<8))*0.1;
              for (i = 0; i < 16; i++) {
                tdata[i]=(rbuf[(i*2+2)]+(rbuf[(i*2+3)]<<8))*0.1;
              }              

              // Checking for packet error according to the sensor datasheet instructions
              if(D6T_checkPEC(34)) {
                // Success in check PEC
                output_data(1);  // Sends data via serial port    
              } else {
                // Failure in check PEC
                output_data(0);  // Sends data via serial port    
              }
            }
        } // Closes if (inByte == 0x0001)
  } // Closes if(Serial.available() > 0)
} // Closes void loop()

// checkPEC: 1 represents reliable packet, and 0 not reliable
void output_data(int checkPEC) {
  char stringAux[8] = "";
  char stringSerialPrint[64] = "";
  int tdataInt[16];
  int t_PTAT_int;
  // Convert matrix temperatures in int because sprintf
  // does not work on Arduino with floats
  for (int w = 0; w < 16; w++ ){
    tdataInt[w] = ((int) (tdata[w] * 10)); // eliminates the fractional part
  }
  t_PTAT_int = ((int) (t_PTAT * 10)); // eliminates the fractional part

  // The following code sends data once to the serial port
  // The data are represented as follows: (t_PTAT, t1, t2, ..., t16, checkPEC)
  // checkPEC values: 1 (success) or 0 (failure)
  // But '(', ')' and ',' are not sent. Each temperature is composed of 3 chars.
  // So 229300125 means 3 temperatures: 22.9, 30.0 and 12.5 degrees Celsius
  sprintf(stringAux, "%d", t_PTAT_int);
  strcat(stringSerialPrint, stringAux);
  // Iterates over matrix temperatures
  for (int i = 0; i < 16; i++) {
    sprintf(stringAux, "%d", tdataInt[i]);
    strcat(stringSerialPrint, stringAux);
  }
  sprintf(stringAux, "%d", checkPEC);
  strcat(stringSerialPrint, stringAux);
  Serial.println(stringSerialPrint); // Send data through Serial
}


unsigned char calc_crc( unsigned char data ) {
   int  index;
   unsigned char  temp;
  for(index=0;index<8;index++){ 
    temp = data;
    data <<= 1;
    if(temp & 0x80) data ^= 0x07;
  }
  return data;
}
int  D6T_checkPEC(int pPEC)
{
   unsigned char  crc;
   int  i;
   crc = calc_crc(0x15);
   for(i=0;i<pPEC;i++){
      crc = calc_crc( rbuf[i] ^ crc );
   }
   return (crc == rbuf[pPEC]);
}
