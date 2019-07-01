#
# New ABC Program for Type 2 and 3 Fishery
#

abc_t23 <- function(
  catch,   # catch timeseries data
  cpue=NULL,   # cpue timeseries data
  BT=0.75,   # initial target level
  tune.par = c(0.4,0.5,1.0), #  tuning parameters: (beta, delta, lambda) 
  PL=0.7,   #  BL = PL*BT
  PB=0.0,   #  BB = PB*BT
  catch.only=FALSE,    # catch only method
  default=TRUE,
  n.catch=5   #  period for averaging the past catches
){
  #
  # C[t+1] = C[t]*exp(k*(D-BT))
  # 
  
  if (default & (sum(cpue,na.rm=TRUE)==0 | catch.only)) {catch.only <- TRUE; tune.par <- c(1.5,2,0); BT <- 0.1; PL <- 2; PB <- 10}
  
  beta <- tune.par[1]   # velocity to go to BT
  delta <- tune.par[2]   # correction factor when D <= BL
  lambda <- tune.par[3]   # tuning parameter for updating BT

  n <- length(catch)   # the number of catch data

  cum.cpue <- function(x) pnorm(scale(x),0,1) # cumulative normal distribution
  
  if (catch.only){
    max.cat <- max(catch,na.rm=TRUE)    # max of catch
    D <- catch/max.cat
    cD <- D[n]            # current catch level

    AAV <- NA

    BT <- BT      # Btarget
    BL <- PL*BT      # Blimit
    BB <- PB*BT      # Bban

    BRP <- c(BT, BL, BB)
 
    k <- ifelse(cD < BB, -(beta+(cD >= BL)*delta*(BL-cD)/(cD-BB)), -Inf)     #  calculation of k    
    abc <- ifelse(cD < BB, mean(catch[(n-n.catch+1):n])*exp(k*(cD-BT)), 0)     # calculation of ABC
  
    Obs_BRP <- max.cat*c(BT, BL, BB)
    Current_Status <- c(D[n],catch[n])
    names(Current_Status) <- c("Level","Catch")
  } else {
    D <- cum.cpue(as.numeric(cpue))              # cumulative probability of cpue
    mD <-  attributes(D)$'scaled:center'         # mean of cpue
    sD <- attributes(D)$'scaled:scale'           # standard deviation of cpue
    cD <- D[n]                                   # final depletion
  
    icum.cpue <- function(x) sD*qnorm(x,0,1)+mD   # inverse function from D to CPUE
  
    BT <- BT      # Btarget
    BL <- PL*BT      # Blimit
    BB <- PB*BT      # Bban

    BRP <- c(BT, BL, BB)

    if (lambda > 0) AAV <- aav.f(cpue) else AAV <- 0

    k <- ifelse(cD > BB, beta+(cD <= BL)*delta*exp(lambda*log(AAV^2+1))*(BL-cD)/(cD-BB), Inf)    #  calculation of k
    abc <- ifelse(cD > BB & cpue[n] > 0, mean(catch[(n-n.catch+1):n],na.rm=TRUE)*exp(k*(cD-BT)), 0)    # calculation of ABC
    
    Obs_BRP <- c(icum.cpue(BT), icum.cpue(BL), icum.cpue(BB))
    Current_Status <- c(D[n],cpue[n])
    names(Current_Status) <- c("Level","CPUE")
  }

    names(BRP) <- names(Obs_BRP) <- c("Target","Limit","Ban")
    
    output <- list(BRP=BRP,Obs_BRP=Obs_BRP,Current_Status=Current_Status,catch.only=catch.only,AAV=AAV,tune.par=tune.par,k=k,ABC=abc)

  return(output)
}

aav.f <- function(x){
  n <- length(x)
  aav <- 2*abs(x[2:n]-x[1:(n-1)])/(x[2:n]+x[1:(n-1)])
  aav <- ifelse(aav < Inf, aav, NA)
  mean(aav,na.rm=TRUE)
}

diag.plot <- function(dat,res,lwd=3,cex=1.5,legend.location="topleft",main=""){
  Year <- dat$Year
  Catch <- dat$Catch
  CPUE <- dat$CPUE

  n <- length(Catch)   # the number of catch data

  if (res$catch.only) {
    D <- Catch/max(Catch,na.rm=TRUE)
    Level.name <- "Harvest Level"
  } else {
    cum.cpue <- function(x) pnorm(scale(x),0,1) # cumulative normal distribution
    D <- cum.cpue(as.numeric(CPUE))
    Level.name <- "Depletion Level"
  }
  
  Catch.change <- c(Catch[2:n]/Catch[1:(n-1)],res$ABC/Catch[n])
  D.change <- c(D[-1],NA)
  
  plot.range <- range(c(0,1),Catch.change, D.change,na.rm=TRUE)
  
  year <- c(Year[-1],Year[n]+1)
  
  plot(year,Catch.change,type="b",xlab="Year",ylab="",lwd=lwd,col=c(rep("blue",n-1),"brown"),ylim=plot.range,pch=c(rep(16,n-1),18),cex=cex,main=main,lty=2)
  lines(year,D.change,col="orange",lwd=lwd,lty=1)
  abline(h=res$BRP,lty=1:3,col=c("green","yellow","red"),lwd=lwd)
  legend(legend.location,c(expression(C[t]/C[t-1]),Level.name),col=c("blue","orange"),lwd=lwd,lty=c(1,2),cex=cex)
}

