AR.Drone 2.0 R API
========================================================
author: Ido Bar
date: 15/09/2015

AT commands
========================================================

- The AR.Drone 2.0 is controlled by low-level AT* commands that are sent as text strings via UDP packets (port=5556. IP=192.168.1.1).
Example: ```AT*CONFIG=1,control:altitude_max,2000\r```  
This example sets the maximum altitude to 2m.
- Each command ends with a \<LF\> character (coded by R with \r).
- Some of the arguments sent to the drone are plain integers, while others are 32bit signed integer representing binary or floats (will be further discussed)
- The drone must recieve a signal from the WiFi connection at least once a second (every 50-100ms recommended), or the connection will drop.


Additional reading materials
========================================================
Drone commands:
- [Programming ARDrone](http://www.robotappstore.com/Knowledge-Base/Programming-ARDrone/101.html)
- [AT commands for AR.Drone](https://abstract.cs.washington.edu/~shwetak/classes/ee472/assignments/lab4/drone_api.pdf)  

Float to 32bit signed integer word conversion example:

(float)0.05=(int)1028443341 
(float)-0.05=(int)-1119040307

- [Decimal to Hex coversion](http://www.h-schmidt.net/FloatConverter/IEEE754.html)
- [Hex to signed integer conversion](http://www.binaryconvert.com/convert_signed_int.html)

Prerequisite
========================================================

In order to run the script, you'd need the following:

- Install [Nmap](https://nmap.org/download.html), make sure you allow it to include the installation directory in your system path.
- If working in windows, you can simply download the [Ncat](http://nmap.org/dist/ncat-portable-5.59BETA1.zip) zip file and extract ncat.exe to a folder in your path or to your working directory.
- Place the file Float_2_Int.csv (should be included with the AR_Drone_API.zip archive) in your working directory

