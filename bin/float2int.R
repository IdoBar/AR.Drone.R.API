# Install missing packages if needed
list.of.packages <- c("stringi")

for (package in list.of.packages) {
  if (!require(package, character.only=T, quietly=T)) {
    install.packages(package)
    require(package, character.only=T)
  }
}

str2num <- function(x) {
  y <- as.numeric(strsplit(x, "")[[1]])
  sum(y * 2^rev((seq_along(y)-1)))
}

options(digits = 22)
find_mantissa <- function(f) {
  i <- 1 ; rem <- abs(f-trunc(f)) ; mantissa <- NULL
  man_dec_point <- FALSE
  while (length(mantissa)<24) {
    temp_rem <- rem-2^-i
    if (!isTRUE(man_dec_point)) {
      if (temp_rem>=0) {
        man_dec_point <- TRUE 
        mantissa <- "." 
      }
    } else {
      mantissa<-c(mantissa,ifelse(temp_rem>=0, "1", "0"))
    }
    rem <- ifelse(temp_rem>=0, temp_rem, rem)
    i<-i+1 
    next
  }
  return(c(paste0(mantissa[-1], collapse=""),24-i))
}


dec2bin<-function(p_number) {
  bsum<-0
  bexp<-1
  while (p_number > 0) {
    digit<-p_number %% 2
    p_number<-floor(p_number / 2)
    bsum<-bsum + digit * bexp
    bexp<-bexp * 10
  }
  return(bsum)
}

dec2binstr<-function(p_number) {
  bin_str<-NULL

  while (p_number > 0) {
    digit<-p_number %% 2
    p_number<-floor(p_number / 2)
    bin_str<-paste0(digit,bin_str)
  }
  return(bin_str)
}

float2Int <- function(decfloat){
  bit32 <- ifelse(decfloat<0,-1, 1)
  mantissa <- find_mantissa(decfloat)
  exp <- dec2binstr(127+as.numeric(mantissa[2]))
  long_exp <- paste0(rep("0",8-stri_length(exp)),exp)
  unsigned <- paste0(long_exp,mantissa[1] )
  if (decfloat<0) {
    unsigned <- sapply(lapply(strsplit(unsigned, split=NULL), 
                              function(x) ifelse(x=="0","1", "0")), paste0, collapse="")
  }
  binary <- paste0("0",unsigned)
  return(c(binary, bit32*str2num(binary)))
}




