// omron_d6t_viewer.pde
// D6T-44L data receiver/visualization/persistent. 
// This program requests and receives temperature data from Arduino. This program also shows the temperatures on a 4x4 matrix layout using colors 
// for temperature representation. Press 'q' for finishing the execution.
// Author: Bruno Silva Pontes.
// Beginning of development: April 2016

/* Tips: 
 * Arduino serial buffer length is 64 bytes. (Source: www.arduino.cc/en/Serial/Available)
 * Remember to check what is the int serialport parameter.
 More red means hotter and more blue means cooler.
 */
 
 
 /* Improvements: 
 
 April 2016 -=- Writes measures (and features) to text file.
 */
 
 
import processing.serial.*; // serial interface to comunicate with Arduino
 
int[] tdata = new int[17]; // Array to put the temperature (also considered 17 element content ensure that come in lump PTAT)
int tptat; // PTAT
String portName; 
int serialport = 2; // For specifying the serial port number to connect
                    // On Mac: /dev/tty.*
String buf; // Temperature data reception
// More Red means hotter and more Blue means cooler
color tcolor;
PrintWriter outputFile; 
Serial myPort;  // Create object from Serial class
String txtFileLine;
String auxTemperature;
int previousMillis;
int redColor;
int blueColor;
boolean isFirstRecord = true;
 
void setup() {
  size(640,640);
  println(Serial.list()); // list all the available serial ports
  portName = Serial.list()[serialport];
  myPort = new Serial(this, portName, 9600);
  myPort.clear();
  
  // Creates file for saving temperature data and features
  try {
    outputFile = createWriter("OUTPUT-TEXT-FILE.txt");
  } catch (Exception e) {
    e.printStackTrace();
    exit(); // Stops the program
  }
  
  outputFile.println(DateTimeNow() + " BEGINNING OF FILE");
  outputFile.println("TPTAT, T1, T2, T3, T4, T5, T6, T7, T8, T9, T10, T11, T12, T13, T14, T15, T16, CheckPEC, Delta t from last measure in Miliseconds, Time Stamp");
  
}
void draw() {
  myPort.write(0x01); // requests data
  delay(200); // Wait (for not immediately check for sending messages at serial port)
 
  println("Waiting for temperatures values");
  while (myPort.available() > 0) { // When comes data to the serial port
    //delay(150); // waiting for thansmiting the entire data
    buf = myPort.readString(); // Reception
    myPort.clear();  // Clear of serial port receive buffer
    println("step 1 (while) ok");
    
    
    // The data are represented as follows: (t_PTAT, t1, t2, ..., t16, checkPEC)
    // checkPEC values: 1 (success) or 0 (failure)
    // But '(', ')' and ',' are not sent. Each temperature is composed of 3 chars.
    // So 229300125 means 3 temperatures: 22.9, 30.0 and 12.5 degrees Celsius
    println("buf.length() = " + buf.length());
    if(buf.length() == 54){ // I do not know why buf.length() is 54 instead of 52
      println("step 2 (buf.length == 54) ok");
      try {
        tptat = int(buf.substring(0, 3));
        txtFileLine = buf.substring(0, 3); // TPTAT
        println("TPTAT =  " + txtFileLine);        
        // Concatenates temperatures
        for(int u = 0; u < 16; u++) { 
          tdata[u] = int(buf.substring(3*(u + 1), (3*(u + 2))));
          txtFileLine = txtFileLine + ", " + buf.substring(3*(u + 1), (3*(u + 2)));
        }
        
        txtFileLine = txtFileLine + ", " + buf.substring(51, 52) + ", ";// Check PEC
        println(buf.substring(51, 52));
        if (isFirstRecord == true) {
          isFirstRecord = false;
          previousMillis = millis();
        } else {
          txtFileLine = txtFileLine + str(millis() - previousMillis) + ", ";
          txtFileLine = txtFileLine + DateTimeNow(); // Time stamp
          outputFile.println(txtFileLine); // Writes data to dataset text file
          previousMillis = millis();
        }
        
        
      } catch (Exception e) {
        println("Thrown exception from string concatenation");
        outputFile.println(DateTimeNow() + " ERROR");
        outputFile.flush(); // Writes the remaining data to the file
        outputFile.close(); // Finishes the file
        exit(); // Stops the program
      } 
      
      // Iterates over matrix temperatures
      for (int i = 0; i < 16; i++) { // Set the color for each area, to draw a square
        // Defines the PIXEL COLOR for each temperature (More Red means hotter and more Blue means cooler)
        if(tdata[i] >= 350) {
          redColor = 255; // Maximum value
          blueColor = 0; // Minimum value
        } else {
          if(tdata[i] <= 290) {
              redColor = 0;
              blueColor = 255;
          } else {
            blueColor = int((350 - tdata[i]) * 4.25);
            redColor = int((tdata[i] - 290) * 4.25);
          }
        }
        tcolor = color(redColor,0,blueColor);
        fill(tcolor);        
      
        rect((i % 4)*160, (i / 4)*160, (i % 4)*160+160, (i / 4)*160+160);
        if (tdata[i]<5) {fill(255);} else {fill(0);}
        textAlign(CENTER, CENTER);
        textSize(20);
        // Converts 100 to 10.0°C
        auxTemperature = str(tdata[i]).substring(0, 2) + "." + str(tdata[i]).substring(2, 3) + "°C";
        text(auxTemperature,(i % 4)*160+80, (i / 4)*160+80);
      } // Closes for
    } // Closes if(buf.length) 
    
  } // Closes while (myPort.available() > 0)
} // Closes void draw()

// does the key pressed event occur
void keyPressed() {
        //outputFile.println(key); // write key to file, should start the clock
        if (key == 'q') {   // 'q' to quit the program
          outputFile.println(DateTimeNow() + " END OF FILE");
          outputFile.flush(); // Writes the remaining data to the file
          outputFile.close(); // Finishes the file
          exit(); // Stops the program
        }
}

String DateTimeNow(){
  String auxMonth = String.valueOf(month());
  String auxDay = String.valueOf(day());
  String auxHour = String.valueOf(hour());
  String auxMinute = String.valueOf(minute());
  String auxSecond = String.valueOf(second());
  String auxYear = String.valueOf(year());
  String auxDateNow = auxYear + "/" + auxMonth + "/" + auxDay + " - " + auxHour + ":" + auxMinute + ":" + auxSecond;
  
  return auxDateNow;
}