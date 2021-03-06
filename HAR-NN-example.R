#### KOSPI real data analysis.

## Set the working directory
setwd('C:/Users/coms/Desktop/R code for real data analysis') 

install.packages("readxl") # CRAN version

library(readxl)

## Multinational Realized variance Data
fulldata <-read_excel("OxfordManRealizedVolatilityIndices(20160928).xlsx", na = "NA")

head(fulldata)
nrow(fulldata)
ncol(fulldata)

# KOSPI (measured per 5-minutes) realized variance data
KOSPI.data <- fulldata[,c(1,192)]

head(KOSPI.data)

## Data handling
KOSPI.0615.data<-KOSPI.data[1570:4182,] ## from 2006. 1. 2. to 2015. 12. 31.  
head(KOSPI.0615.data)
tail(KOSPI.0615.data)
nrow(KOSPI.0615.data) ## 2,613 daily realized volatility series.

### Transformation to Realized Volatility (RV) value (Take square root to the KOSPI realized variance data). 

aa1 <- KOSPI.0615.data[,1]  

aa <- as.data.frame(KOSPI.0615.data[,2]) 

aa[[1]] 

aa <- as.numeric(aa[[1]])

aa2 <-sqrt(aa) 

KOSPI.0615.data.RV <- cbind(aa1,aa2) 

head(KOSPI.0615.data.RV)

colnames(KOSPI.0615.data.RV)<-c("DATE","Realized.Volatility")



#### KOSPI RV series.

KOSPI.0615.data.RV 


head(KOSPI.0615.data.RV)
tail(KOSPI.0615.data.RV)

KOSPI.0615.data.RV2 <- KOSPI.0615.data.RV[,2]
(which(is.na(KOSPI.0615.data.RV2)))

plot.ts(KOSPI.0615.data.RV2)

title('20060102 ~ 20151231 RV series(KOSPI)5-minutes')

par(mfrow=c(2,2))
plot.ts(KOSPI.0615.data.RV2)
acf(KOSPI.0615.data.RV2)
pacf(KOSPI.0615.data.RV2)
qqnorm(KOSPI.0615.data.RV2)


# RV(d) : given data.

# RV(w) : 1/5* [ Rv_(t)(d)+.....Rv_(t-4d)(d) ].

# Rv(m) : 1/22* [ Rv_(t)(d)+.....Rv_(t-21d)(d) ].

## HAR-RV model : Rv_(t+1d)(d) = beta0 + beta1*Rv(t)(d) + beta2*Rv(t)(w) + beta3*Rv(t)(m) + WN(error).



## Make complete data set using linear interpolation (using 'approx' built-in function in R).

## First of all, we eliminate the last RV series data (2015.12.31) which is a missing value and last daily time point data.
## Why we implement this kind of ellimination is in order to apply linear interpolation to a given RV dataset.
## That is; if there is a missing value in the data of the first time point and the data of the last time point (of all data set),
## we can not apply linear interpolation to that real data.
## 

KOSPI.0615.data.RV <- KOSPI.0615.data.RV[-2613,]

KOSPI.0615.data.RV

head(KOSPI.0615.data.RV)
tail(KOSPI.0615.data.RV)
nrow(KOSPI.0615.data.RV) # cardinality : 2,612


KOSPI.0615.data.RV2 <- KOSPI.0615.data.RV[,2]
KOSPI.0615.data.RV2


## Now we have 2,612 complete KOSPI daily RV series data from 2006. 1. 2. to 2015. 12. 30.

install.packages('zoo')
library(zoo)

## use underlying time scale for interpolation.

KOSPI.0615.data.RV3 <- na.approx(KOSPI.0615.data.RV2)

## Complete data set obtained after linear interpolation.
KOSPI.0615.data.RV3 ## use underlying time scale for interpolation (na.approx).

## check whether there is a missing value in the corrected RV series data set.
(which(is.na(KOSPI.0615.data.RV3))) ## 0 
length(KOSPI.0615.data.RV3)



KOSPI.0615.data.RV1 <- KOSPI.0615.data.RV[,1]

## plotting

par(mfrow=c(2,2))
plot.ts(KOSPI.0615.data.RV3,main="2006.1.2 ~ 2015.12.30 RV series (KOSPI) (5-minutes)",xlab="Daily time points (# : 2,612)",ylab="KOSPI daily RV series")
acf(KOSPI.0615.data.RV3,main="ACF")
pacf(KOSPI.0615.data.RV3,main="PACF")
qqnorm(KOSPI.0615.data.RV3)

## Definition of complete RV series.

KOSPI.0615.data.RV <- cbind(KOSPI.0615.data.RV1,KOSPI.0615.data.RV3)
colnames(KOSPI.0615.data.RV) <- c("Date","Realized Volatility")

head(KOSPI.0615.data.RV)
tail(KOSPI.0615.data.RV)
which(is.na(KOSPI.0615.data.RV)) ## 0 => there is no missing value in KOSPI RV series.



n <- nrow(KOSPI.0615.data.RV) # 2,612 
n

# Data of ahead 2,512 daily time points in the complete RV series data set composed of 2,612 daily time points
# is used as a training set. Put the remaining 100 time points into the test set.

# (Note that we assumed that we had already known the optimal 'q' after investigating with validation set.)

# Then we will use the out-of-sample forecasting method to obtain 1-step-ahead MSPE & MAPE (Our model-performance measures).


install.packages('neuralnet')
library(neuralnet)

install.packages('numDeriv')
library('numDeriv')

install.packages('matlib')
library(matlib)
library(MASS)



source("HAR-NN-library.R")

## HAR-NN model : the first NN-based HAR model.

## q (This value is pre-determined through the investigation of our performance measures with training & validation set.)

## ex)  The optimal number of hidden unit ('q') is 5 when sigmoid activation function is used. (for KOSPI RV series)
##      The optimal number of hidden unit ('q') is 10 when tanh activation function is used. (for KOSPI RV series)

# r : maximum iteration number needed to converge the coefficients of NN-based HAR models.


HAR.NN.model.fitting.to.real.RV.series <- function(RV.data,r,acti.fun){
  
  ## The following 'for' code will be repeated from the initial number of training set (#  = nrow(RV.data)-i )
  ## to the just before the last daily time point series data of the entire data set.
  ## That is, the out-of-sample forecastimg method can be implemented as follows.
  
  for(i in 100:1){
    if(acti.fun=="logistic"){
    HAR_NN_forecast(RV.data,i,r,"logistic")
    }
    
    else if(acti.fun=="tanh"){
    HAR_NN_forecast(RV.data,i,r,"tanh")
    }
    
    else
      print("You might have a typo error in 'acti.fun' argument.")
  }
}
  
  
HAR.NN.model.fitting.to.real.RV.series(KOSPI.0615.data.RV,200,"logistic")
  
HAR.NN.model.fitting.to.real.RV.series(KOSPI.0615.data.RV,200,"tanh")



## HAR-infty-NN model : the second NN-based HAR model.

## The optimal number of hidden unit ('q') is 5 when sigmoid activation function is used. (for KOSPI RV series)
## The optimal number of hidden unit ('q') is 10 when tanh activation function is used. (for KOSPI RV series)

# r : maximum iteration number needed to converge the coefficients of NN-based HAR models.


HAR.infty.NN.model.fitting.to.real.RV.series <- function(RV.data,r,acti.fun){
  
  ## The following 'for' code will be repeated from the initial number of training set (#  = nrow(RV.data)-i )
  ## to the just before the last daily time point series data of the entire data set.
  ## That is, the out-of-sample forecastimg method can be implemented as follows.
  
  for(i in 100:1){
    if(acti.fun=="logistic"){
      HAR_infty_NN_forecast(RV.data,i,r,"logistic")
    }
    
    else if(acti.fun=="tanh"){
      HAR_infty_NN_forecast(RV.data,i,r,"tanh")
    }
    
    else
      print("You might have a typo error in 'acti.fun' argument.")
  }
}


HAR.infty.NN.model.fitting.to.real.RV.series(KOSPI.0615.data.RV,200,"logistic")

HAR.infty.NN.model.fitting.to.real.RV.series(KOSPI.0615.data.RV,200,"tanh")



## HAR-AR(22)-NN model : the third NN-based HAR model.

## The optimal number of hidden unit ('q') is 5 when sigmoid activation function is used. (for KOSPI RV series)
## The optimal number of hidden unit ('q') is 10 when tanh activation function is used. (for KOSPI RV series)

# r : maximum iteration number needed to converge the coefficients of NN-based HAR models.


HAR.AR22.NN.model.fitting.to.real.RV.series <- function(RV.data,r,acti.fun){
  
  ## The following 'for' code will be repeated from the initial number of training set (#  = nrow(RV.data)-i )
  ## to the just before the last daily time point series data of the entire data set.
  ## That is, the out-of-sample forecastimg method can be implemented as follows.
  
  for(i in 100:1){
    if(acti.fun=="logistic"){
      HAR_AR22_NN_forecast(RV.data,i,r,"logistic")
    }
    
    else if(acti.fun=="tanh"){
      HAR_AR22_NN_forecast(RV.data,i,r,"tanh")
    }
    
    else
      print("You might have a typo error in 'acti.fun' argument.")
  }
}


HAR.AR22.NN.model.fitting.to.real.RV.series(KOSPI.0615.data.RV,200,"logistic")

HAR.AR22.NN.model.fitting.to.real.RV.series(KOSPI.0615.data.RV,200,"tanh")
