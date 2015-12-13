# set working directory
#setwd("E:/PhD/Teaching/ENG203/Drone")

# define connection
ARDRONE_NAVDATA_PORT = 5554
ARDRONE_VIDEO_PORT = 5555
ARDRONE_COMMAND_PORT = 5556

droneIP <- "192.168.1.1"

# # options to create the connection
# # using socket write.socket(AR_cmd, AT(Cmd))
# AR_cmd <- make.socket(host = droneIP, ARDRONE_COMMAND_PORT)
# AR_nav <- make.socket(host = hostIP, ARDRONE_NAVDATA_PORT)
# 
# # # using ncat
ncat <- function(msg_string){
  ncatOpts <- "-u -vv -e"
  ncatExec <- sprintf('"printf %s"', msg_string)
  ncatArgs <- paste(ncatOpts, ncatExec, droneIP, ARDRONE_COMMAND_PORT ) 
  message(ncatArgs)
# ncat -u -vv --sh-exec 'printf "AT*FTRIM=1\rAT*CONFIG=2,control:altitude_max,1000\rAT*REF=3,290718208\r"' 192.168.1.1 5556
  system2("ncat", args=ncatArgs)
}

# initialise drone, set config default values, define constants.
default_speed <- 0.5
cmdCounter <- 0
maxHeight <- 2000
watchdogInterval <- 0.1
cmdInterval <- 0.03
emergencyCode <- "290717952"
landCode <- "290717696"
takeOffCode <- "290718208"
anim_moves <- c("turn_around", "turn_around_go_down", "flip_ahead", "flip_behind","flip_left", "flip_right")
anim_nums <- c(6,7,16:19)
anim_table <- data.frame(anim_moves, anim_nums)



# convert float to signed integer
f2i_table <- read.csv("Float_2_Int.csv")
colnames(f2i_table) <- c("Float_num", "Hex_num", "Signed_int")
f2i <- function(f) {
  if (f>=(-1) & f<=1) {
    return(f2i_table[f2i_table$Float_num==round(f,1),]$Signed_int)
  } else  return(f2i_table[f2i_table$Float_num==round(default_speed,1),]$Signed_int)
}

# define general AT command syntax
AT <- function(cmd, params_str){
  if (missing(params_str)) msg <- sprintf("AT*%s=%i\\r",cmd, cmdCounter)
  else msg <- sprintf("AT*%s=%i,%s\\r",cmd, cmdCounter, params_str)
  assign("cmdCounter", cmdCounter+1, envir = .GlobalEnv)
  return(msg)
}

# enter emergency mode
drone.emergency <- function() ncat(AT("REF",emergencyCode))

# take off (including horizontal calibration and set maximum height)

drone.take_off <- function(take_off_duration){
  msg <- paste0(AT("FTRIM"), 
                AT("CONFIG", sprintf("control:altitude_max,%i",maxHeight)), 
                AT("REF",takeOffCode))
  ncat(msg)
  elapsed <- 0
  while (elapsed<take_off_duration) {
    # while takeoff is taking place, keep sending watchdog signal
    Sys.sleep(watchdogInterval)
    ncat(AT("COMWDG"))
    #   increment elapsed time
    elapsed <- elapsed + watchdogInterval
  }
  message(sprintf("Drone taking off, waiting: %.2f seconds", take_off_duration))
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

# flight animation


drone.anim <- function(anim, duration){
  anim_code <- anim_table[anim_table$anim_moves==anim,]$anim_nums
  if (missing(duration)) msg <- AT("ANIM", anim_code)
  else msg <- AT("ANIM", paste(anim_code, duration, sep=","))
#  message(msg)
  ncat(msg)
  elapsed <- 0
  while (elapsed<duration) {
    # while animation is performing, keep sending watchdog signal
    Sys.sleep(watchdogInterval)
    ncat(AT("COMWDG"))
#    message(sprintf("Performing <%s> animation, time elapsed: %.2f", anim, elapsed))
#   increment elapsed time
    elapsed <- elapsed + watchdogInterval  
  }
  message(sprintf("Performing <%s> animation, duration: %.2f seconds", anim, elapsed))
}


# flight action command
drone.do <- function(action, duration, speed){
  if (missing(speed)) speed <- default_speed
  elapsed <- 0
  drone_function <- paste("drone",action, sep=".")
  while (elapsed<duration) {
    # using ncat
    msg <- get(drone_function)(speed)
    ncat(msg)
    # wait the defined ms before resending the command
    Sys.sleep(cmdInterval)
    elapsed <- elapsed + cmdInterval
  }
  message(sprintf("Drone movement <%s> performed for %.2f seconds", action, duration))
}  

# start flight sequence
drone_flight <- function(){
  # create the connection
  drone.take_off(1)
  drone.do("hover",2)
#   drone.do("move_forward", 5)
#   drone.do("hover",3)
#   drone.do("move_right", 3)
#   drone.do("hover",3)
#   drone.do("rotate_right", 5)
#   drone.do("up",2)
#   drone.do("down",1)
#   drone.anim("turn_around", 3)
  drone.land()  
}


# run flight
drone_flight()





