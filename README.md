AR.Drone 2.0 R API
========================================================
Author: Ido Bar  
Date: 13/12/2015


##AT commands

- The AR.Drone 2.0 is controlled by low-level AT* commands that are sent as text strings via UDP packets (port=5556. IP=192.168.1.1).
Example: `AT*CONFIG=1,control:altitude_max,2000\r`  
This example sets the maximum altitude to 2 m.
- Each command ends with a \<LF\> character (coded by R with `\\r`).
- Some of the arguments sent to the drone are plain integers, while others are 32bit signed integer representing binary or floats (using float2Int function from [bin/float2int_improved.R](bin/float2int_improved.R))
- The drone must recieve a signal from the WiFi connection at least once a second (every 50-100 ms recommended), or the connection will drop.
- The API will take care of translating the user commands to low-level AT commands and setup a continuous signal transmission.

##Usage

- Create a sequence of commands for the flight sequence (`drone.take_off()` must come first and `drone.land()` last of course).
- `take_off()` argument is the duration of the action, until further command is given.
- Drone movements are called by function `drone.do("direction/action", duration_in_seconds, speed)`.
- Drone speed is an optional argument representing a fraction of the maximum speed on a scale of 0-1. (if not used, a default of 0.5 is used). 
- Drone movement options: hover, up, down, move_right, move_left, move_forward, move_back, rotate_right, rotate_left.
- Pre-defined flight sequences (coded in the drone firmware) are available with the `drone.anim("animation", duration)` function:
  
  'phiM30Deg', 'phi30Deg', 'thetaM30Deg', 'theta30Deg', 'theta20degYaw200deg',
  'theta20degYawM200deg', 'turnaround', 'turnaroundGodown', 'yawShake',
  'yawDance', 'phiDance', 'thetaDance', 'vzDance', 'wave', 'phiThetaMixed',
  'doublePhiThetaMixed', 'flipAhead', 'flipBehind', 'flipLeft', 'flipRight'  
  
 **!!! Use with enough air space and height to allow the drone to perform the animation !!!**
 
###Flight sequence example


    flight sequence:
    drone.take_off(1)  
    drone.do("hover",2)  
    drone.do("move_forward", 5, 0.64)  
    drone.do("hover",3)  
    drone.do("move_right", 3)  
    drone.do("hover",3)  
    drone.do("rotate_right", 5)  
    drone.do("up",2)  
    drone.do("down",1)  
    drone.anim("turnaround", 3)  
    drone.land()  


##Additional reading material

###Drone commands:
- [Programming AR.Drone](http://www.robotappstore.com/Knowledge-Base/Programming-ARDrone/101.html)
- [AT commands for AR.Drone](https://abstract.cs.washington.edu/~shwetak/classes/ee472/assignments/lab4/drone_api.pdf)  

###Float to 32bit signed integer word conversion example:
```
(float)0.05=(int)1028443341  
(float)-0.05=(int)-1119040307
```
- [Decimal to Hex coversion](http://www.h-schmidt.net/FloatConverter/IEEE754.html)
- [Hex to signed integer conversion](http://www.binaryconvert.com/convert_signed_int.html)

##Prerequisites


In order to run the script, you'd need the following (on a windows machine):

- Install [Nmap](https://nmap.org/download.html), make sure you allow it to include the installation directory in your system path.
- If working in windows, you can simply download the [Ncat](http://nmap.org/dist/ncat-portable-5.59BETA1.zip) zip file and extract ncat.exe to a folder in your path or to your working directory.



