# set working directory to the folder containing Float_2_Int.csv and ncat.exe
# setwd("E:/PhD/Teaching/ENG203/Drone")

# utilDir <- file.path(getwd(), "util")
# verify float2int_improved and ncat.exe are available
neededFiles <- c("bin/float2int_improved.R", "bin/win32/ncat.exe")

sapply(neededFiles, function(p) if (!file.exists(file.path(getwd(), p))) {
  message(sprintf("Error: Unable to find necessary file %s, please make sure it's in the working directory, quitting", p))
#  q()
})



# load conversion util
source(neededFiles[1])

# # options to create the connection
# define connection
ARDRONE_NAVDATA_PORT = 5554
ARDRONE_VIDEO_PORT = 5555
ARDRONE_COMMAND_PORT = 5556

droneIP <- "192.168.1.1"

# initialise drone, set config default values, define constants.
default_speed <- 0.5
cmdCounter <- 0
maxHeight <- 2000
watchdogInterval <- 0.1
cmdInterval <- 0.03
# integer representation of binary codes (could be calculated) using 
# landCode <- strtoi("10001010101000000000000000000", base=2)
# takeoffCode <- landCode + strtoi("1000000000", base=2)
# emergencyCode <- landCode + strtoi("0100000000", base=2)
emergencyCode <- "290717952"
landCode <- "290717696"
takeOffCode <- "290718208"

# helper functions
# using ncat to send UDP packets to the drone
ncat <- function(msg_string){
  ncatOpts <- "-u -e"
  ncatExec <- sprintf('"printf %s"', msg_string)
  ncatArgs <- paste(ncatOpts, ncatExec, droneIP, ARDRONE_COMMAND_PORT ) 
  #  message(ncatArgs)
  # ncat -u -vv -e "printf AT*FTRIM=1\rAT*CONFIG=2,control:altitude_max,1000\rAT*REF=3,290718208\r" 192.168.1.1 5556
  system2("ncat", args=ncatArgs)
}

# convert float to signed integer (need to find out how to calculate this for any value in the range [-1:1])
# f2i_table <- read.csv("Float_2_Int.csv")
# colnames(f2i_table) <- c("Float_num", "Hex_num", "Signed_int")
f2i <- function(f) {
  if (f>=(-1) & f<=1) {
    return(float2Int(f)[2])
  } else return(float2Int(default_speed)[2])
}

# define general AT command syntax
AT <- function(cmd, params_str){
  if (missing(params_str)) msg <- sprintf("AT*%s=%i\\r",cmd, cmdCounter)
  else msg <- sprintf("AT*%s=%i,%s\\r",cmd, cmdCounter, params_str)
  assign("cmdCounter", cmdCounter+1, envir = .GlobalEnv)
  return(msg)
}


# Ar.Drone API functions

# enter emergency mode
drone.emergency <- function() ncat(AT("REF",emergencyCode))

# take off (including horizontal calibration and set maximum height)

drone.take_off <- function(take_off_duration){
  msg <- paste0(AT("FTRIM"), 
                AT("CONFIG", sprintf("control:altitude_max,%i",maxHeight)), 
                AT("REF",takeOffCode))
  ncat(msg)
  elapsed <- 0
  message(sprintf("Drone taking off, waiting: %.2f seconds", take_off_duration))
  while (elapsed<take_off_duration) {
    # while takeoff is taking place, keep sending watchdog signal
    Sys.sleep(watchdogInterval)
    ncat(AT("COMWDG"))
    #   increment elapsed time
    elapsed <- elapsed + watchdogInterval
  }
  
}

# landing
drone.land <- function() {
  ncat(AT("REF",landCode))
  message("Drone landed safely (hopefuly...)")
}
# define drone movements commands
drone.hover <- function(speed){
  return(AT("PCMD", "0,0,0,0,0"))
}
drone.up <- function(speed){
  params <- paste(1,0,0,f2i(speed),0, sep=",")
  return(AT("PCMD", params))
}
drone.down <- function(speed){
  params <- paste(1,0,0,f2i(-speed),0, sep=",")
  return(AT("PCMD", params))
}
drone.move_right <- function(speed){
  params <- paste(1,f2i(speed),0,0,0, sep=",")
  return(AT("PCMD", params))
}
drone.move_left <- function(speed){
  params <- paste(1,f2i(-speed),0,0,0, sep=",")
  return(AT("PCMD", params))
}
drone.move_forward <- function(speed){
  params <- paste(1,0,f2i(-speed),0,0, sep=",")
  return(AT("PCMD", params))
}
drone.move_back <- function(speed){
  params <- paste(1,0,f2i(speed),0,0, sep=",")
  return(AT("PCMD", params))
}
drone.rotate_right <- function(speed){
  params <- paste(1,0,0,0,f2i(speed), sep=",")
  return(AT("PCMD", params))
}
drone.rotate_left <- function(speed){
  params <- paste(1,0,0,0, f2i(-speed),sep=",")
  return(AT("PCMD", params))
}

# flight animations
# integer codes of pre-defined animations (more available at)
anim_moves <- c('phiM30Deg', 'phi30Deg', 'thetaM30Deg', 'theta30Deg', 'theta20degYaw200deg',
                'theta20degYawM200deg', 'turnaround', 'turnaroundGodown', 'yawShake',
                'yawDance', 'phiDance', 'thetaDance', 'vzDance', 'wave', 'phiThetaMixed',
                'doublePhiThetaMixed', 'flipAhead', 'flipBehind', 'flipLeft', 'flipRight')
anim_nums <- c(0:19)
anim_table <- data.frame(anim_moves, anim_nums)

drone.anim <- function(anim, duration){
  anim_code <- anim_table[anim_table$anim_moves==anim,]$anim_nums
  if (missing(duration)) msg <- AT("ANIM", anim_code)
  else msg <- AT("ANIM", paste(anim_code, duration, sep=","))
#  message(msg)
  ncat(msg)
  elapsed <- 0
message(sprintf("Performing <%s> animation, duration: %.2f seconds", anim, duration))
  while (elapsed<duration) {
    # while animation is performing, keep sending watchdog signal
    Sys.sleep(watchdogInterval)
    ncat(AT("COMWDG"))
#    message(sprintf("Performing <%s> animation, time elapsed: %.2f", anim, elapsed))
#   increment elapsed time
    elapsed <- elapsed + watchdogInterval  
  }
  
}


# flight action command
drone.do <- function(action, duration, speed){
  if (missing(speed)) speed <- default_speed
  elapsed <- 0
  drone_function <- paste("drone",action, sep=".")
  message(sprintf("Performing drone movement <%s> for %.2f seconds", action, duration))
  while (elapsed<duration) {
    # using ncat
    msg <- get(drone_function)(speed)
    ncat(msg)
    # wait the defined ms before resending the command
    Sys.sleep(cmdInterval)
    elapsed <- elapsed + cmdInterval
  }
  
}  

# start flight sequence
drone_flight_plan <- function(){
  #########################################################################################################
#   enter here all the commands for the flight sequence (take_off must come first and land last of course)
#   take_off argument is the duration of the action, until further command is given
#   drone movements are called by function drone.do("direction/action", duration_in_seconds, speed)
#   drone speed, is an optional argument representing a fraction of the maximum speed on a scale of 0-1.
#   (if not used, a default of 0.5 is used). drone movement options: 
#   hover, up, down, move_right, move_left, move_forward, move_back, rotate_right, rotate_left.
#   pre-defined flight sequences (coded in the drone firmware) are available (with duration in seconds):
#   
#   'phiM30Deg', 'phi30Deg', 'thetaM30Deg', 'theta30Deg', 'theta20degYaw200deg',
#     'theta20degYawM200deg', 'turnaround', 'turnaroundGodown', 'yawShake',
#     'yawDance', 'phiDance', 'thetaDance', 'vzDance', 'wave', 'phiThetaMixed',
#     'doublePhiThetaMixed', 'flipAhead', 'flipBehind', 'flipLeft', 'flipRight'
#   !!! Use with enought air space and height to allow the drone to perform the animation  !!!!
  #
  # Todo: 
  # 1. Change the function to take a line from a data frame with action, and arguments (speed, duration)
  # and add them all to the flight sequence, use lapply, sapply or aaply (from plyr package)  
  # to run a function on each row of a dataframe.
  # 2. Add additional checks on input data (durations, speed, function) 
  # 3. Add protection for lost signal
  # 4. Extract and analyse NavData stream
  #####################################################################################################
  # flight sequence:
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
}


# run flight according to the defined flight sequence
drone_flight_plan()





