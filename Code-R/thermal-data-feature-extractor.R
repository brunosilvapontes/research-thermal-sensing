# This program is responsible for pre processing array thermal data from OMRON D6T 44L.  
# 
# Author: Bruno Silva Pontes
# 
# Software base change control:
# Version   Date        Author                  Description
# 1        29/5/2016    Bruno Silva Pontes      Started the development.
# 
# 


# ------------------------- FUNCTIONS ------------------------------------------
# Gets the highest temperature value for each record and calculates its mean
GetMeanOfHighestTemp <- function(matrixThermalData){
  
  highestTemps <- c()
  
  for(i in 1:nrow(matrixThermalData)){
    # Gets the ith record (all 16 values (raw matrix temperatures))
    auxMatrixThermalData <- as.numeric(matrixThermalData[i,])
    
    # Gets the highest temperature of the record and add it to a list
    highestTemps <- c(highestTemps, max(auxMatrixThermalData))
    
  } # Closes for
  
  return(mean(highestTemps))
}

GetHighestTemperaturesList <- function(temperatures){
  highestTemps <- c()
  
  for(i in 1:nrow(temperatures)){
    # Gets the ith record (all 16 values (raw matrix temperatures))
    auxMatrixThermalData <- as.numeric(temperatures[i,])
    
    # Gets the highest temperature of the record and add it to a list
    highestTemps <- c(highestTemps, max(auxMatrixThermalData))
    
  } # Closes for
  
  return(highestTemps)
}

GetBedroomBackSub <- function(tptat){
  return((23.8/24.9)*tptat)
}

# It returns a list that contains all indexes that are neighbors (distance < 2)
Get1Distance4x4MatrixIndexes <- function(matrixIndex){
  indexes <- c()
  
  if(matrixIndex == 1) indexes <- c(2, 5, 6) 
  if(matrixIndex == 2) indexes <- c(1, 3, 6, 7, 5) 
  if(matrixIndex == 3) indexes <- c(2, 4, 6, 7, 8) 
  if(matrixIndex == 4) indexes <- c(3, 7, 8) 
  if(matrixIndex == 5) indexes <- c(2, 1, 6, 10, 9) 
  if(matrixIndex == 6) indexes <- c(1, 2, 3, 5, 7, 9, 10, 11) 
  if(matrixIndex == 7) indexes <- c(2, 3, 4, 6, 8, 10, 11, 12) 
  if(matrixIndex == 8) indexes <- c(4, 3, 7, 11, 12) 
  if(matrixIndex == 9) indexes <- c(5, 6, 10, 14, 13) 
  if(matrixIndex == 10) indexes <- c(5, 6, 7, 9, 11, 13, 14, 15) 
  if(matrixIndex == 11) indexes <- c(6, 7, 8, 10, 12, 14, 15, 16) 
  if(matrixIndex == 12) indexes <- c(8, 7, 11, 15, 16) 
  if(matrixIndex == 13) indexes <- c(9, 10, 14) 
  if(matrixIndex == 14) indexes <- c(13, 9, 10, 11, 15) 
  if(matrixIndex == 15) indexes <- c(14, 10, 11, 12, 16)
  if(matrixIndex == 16) indexes <- c(15, 11, 12)
  
  return(indexes)
}

# Returns 1 if heatMatrixIndex in one of the bed matrix indexes and it returns 0 if not.
BedroomBedMatrixIndexes <- function(heatMatrixIndex){
  bedMatrixIndexes <- c(9, 10, 11, 12, 13, 14, 15, 16)
  
  if (heatMatrixIndex %in% bedMatrixIndexes){
    return(1)
  } else {
    return(0)
  }
}

# Returns 1 if heatMatrixIndex in one of the floor matrix indexes and it returns 0 if not.
BedroomFloorMatrixIndexes <- function(heatMatrixIndex){
  floorMatrixIndexes <- c(1, 2, 3, 4, 5, 6, 7, 8)
  
  if (heatMatrixIndex %in% floorMatrixIndexes){
    return(1)
  } else {
    return(0)
  }
}

writeMachineLearningTextFile <- function(stringClass, filePath, thermalDataFrame, featureSelection, wekaInputFile){
  
  result <- tryCatch({
    machineLearningFile <- file(filePath, open = "w", encoding = "UTF-8")  
    arffDataFile <- file(wekaInputFile, open = "a", encoding = "UTF-8")
  }, error = function(cond) {
    stop("Erro on creating weka input file")
  })
  
  machineLearningData <- c()
  
  # Iterates over recorded thermal data records
  for (i in 1:nrow(thermalDataFrame)){
    backSubValue <- GetBedroomBackSub(as.numeric(as.character(thermalDataFrame[i, 1])))
    
    # Feature #1 - Difference from hottest pixel to background subtraction value
    feature1 <- (max(thermalDataFrame[i, 2:17]) - backSubValue)
    
    # Feature #2 - Number of pixels after background subtraction
    feature2 <- 0
    valuesAfterBackSub <- c()
    # Iterates over pixel temperatures
    for (u in 2:17) {
      if(thermalDataFrame[i, u] > backSubValue) {
        feature2 <- feature2 + 1
        valuesAfterBackSub <- c(valuesAfterBackSub, thermalDataFrame[i, u])
      }
    }
    
    if (featureSelection == TRUE) { # It will contain only features (...)
      # Defines a machine learning text line (one example with its features and class)
      if(feature2 > 0){
        valuesAfterBackSubMinusBackSubValue <- c()
        for(b in valuesAfterBackSub){
          valuesAfterBackSubMinusBackSubValue <- c(valuesAfterBackSubMinusBackSubValue, (b - backSubValue))
        }  
      }
      
      highestTempIndex <- 0
      secondHighestTempIndex <- 0
      
      # Feature #3
      if(feature2 > 1){
        highestTemp <- (max(thermalDataFrame[i, 2:17]))
        secondHighestTemp <- (sort(thermalDataFrame[i, 2:17], decreasing = TRUE))[2]
        
        # Gets the highest and second highest temperatures indexes
        for (a in 2:17) {
          if(thermalDataFrame[i, a] == highestTemp && highestTempIndex == 0) {
            highestTempIndex <- (a - 1)
          } else {
            if(thermalDataFrame[i, a] == secondHighestTemp && secondHighestTempIndex == 0){
              secondHighestTempIndex <- (a - 1)
            }
          }
        } # Closes for (a in 2:17)
        
        # Checks whether they are neighbors or the matrix distance is higher than 1
        if(secondHighestTempIndex %in% Get1Distance4x4MatrixIndexes(highestTempIndex)){
          feature3 <- 0
        } else {
          feature3 <- 1 # There is discontinuity of heat
        }
        
        # Feature #4
        feature4 <- sd(valuesAfterBackSubMinusBackSubValue)
        
      } else { # Closes if (feature2 > 1)
        feature3 <- 0
        feature4 <- 0
        
      } # Closes if feature2 <= 1
      
      # Feature #5 and #6
      if(feature2 > 0){
        feature5 <- Reduce("+", valuesAfterBackSubMinusBackSubValue)
        feature6 <- mean(valuesAfterBackSubMinusBackSubValue)
      } else {
        feature5 <- 0
        feature6 <- 0
      }
      
      # Features #7 and #8. Where main heat source is at matrix. Respectively bed and floor.
      # Only one of them (#7 and #8) will be 1. The another will be 0.
      feature7 <- BedroomBedMatrixIndexes(highestTempIndex)
      feature8 <- BedroomFloorMatrixIndexes(highestTempIndex)
      
      # Features #9 and #10. Where second main heat source is at matrix. Respectively bed and floor.
      # Only one of them (#9 and #10) will be 1. The another will be 0.
      feature9 <- BedroomBedMatrixIndexes(secondHighestTempIndex)
      feature10 <- BedroomFloorMatrixIndexes(secondHighestTempIndex)
      
      # Defines a machine learning text line (one example with its features and class)
      auxString <- paste(toString(specify_decimal(feature1, 1)), ",", sep="") # feature 1
#       auxString <- paste(auxString, toString(feature2), sep="") # feature 2
#       auxString <- paste(auxString, ",", sep="")
#       auxString <- paste(auxString, toString(feature3), sep="")  # feature 3
#       auxString <- paste(auxString, ",", sep="")
      auxString <- paste(auxString, toString(specify_decimal(feature4, 1)), sep="")  # feature 4
      auxString <- paste(auxString, ",", sep="")
      auxString <- paste(auxString, toString(specify_decimal(feature5, 1)), sep="")  # feature 5
      auxString <- paste(auxString, ",", sep="")
      auxString <- paste(auxString, toString(specify_decimal(feature6, 1)), sep="")  # feature 6
      auxString <- paste(auxString, ",", sep="")
#       auxString <- paste(auxString, toString(feature7), sep="") # feature 7
#       auxString <- paste(auxString, ",", sep="")
#       auxString <- paste(auxString, toString(feature8), sep="") # feature 8
#       auxString <- paste(auxString, ",", sep="")
#       auxString <- paste(auxString, toString(feature9), sep="") # feature 9
#       auxString <- paste(auxString, ",", sep="")
#       auxString <- paste(auxString, toString(feature10), sep="") # feature 10
#       auxString <- paste(auxString, ",", sep="")
      
      auxString <- paste(auxString, stringClass, sep="") # class
      auxString <- trim(auxString)  
      
    } else { # It will add all features
      if(feature2 > 0){
        valuesAfterBackSubMinusBackSubValue <- c()
        for(b in valuesAfterBackSub){
          valuesAfterBackSubMinusBackSubValue <- c(valuesAfterBackSubMinusBackSubValue, (b - backSubValue))
        }  
      }
      
      highestTempIndex <- 0
      secondHighestTempIndex <- 0
      
      # Feature #3
      if(feature2 > 1){
        highestTemp <- (max(thermalDataFrame[i, 2:17]))
        secondHighestTemp <- (sort(thermalDataFrame[i, 2:17], decreasing = TRUE))[2]
        
        # Gets the highest and second highest temperatures indexes
        for (a in 2:17) {
          if(thermalDataFrame[i, a] == highestTemp && highestTempIndex == 0) {
            highestTempIndex <- (a - 1)
          } else {
            if(thermalDataFrame[i, a] == secondHighestTemp && secondHighestTempIndex == 0){
              secondHighestTempIndex <- (a - 1)
            }
          }
        } # Closes for (a in 2:17)
        
        # Checks whether they are neighbors or the matrix distance is higher than 1
        if(secondHighestTempIndex %in% Get1Distance4x4MatrixIndexes(highestTempIndex)){
          feature3 <- 0
        } else {
          feature3 <- 1 # There is discontinuity of heat
        }
        
        # Feature #4
        feature4 <- sd(valuesAfterBackSubMinusBackSubValue)
        
      } else { # Closes if (feature2 > 1)
        feature3 <- 0
        feature4 <- 0
        
      } # Closes if feature2 <= 1
      
      # Feature #5 and #6
      if(feature2 > 0){
        feature5 <- Reduce("+", valuesAfterBackSubMinusBackSubValue)
        feature6 <- mean(valuesAfterBackSubMinusBackSubValue)
      } else {
        feature5 <- 0
        feature6 <- 0
      }
      
      # Features #7 and #8. Where main heat source is at matrix. Respectively bed and floor.
      # Only one of them (#7 and #8) will be 1. The another will be 0.
      feature7 <- BedroomBedMatrixIndexes(highestTempIndex)
      feature8 <- BedroomFloorMatrixIndexes(highestTempIndex)
      
      # Features #9 and #10. Where second main heat source is at matrix. Respectively bed and floor.
      # Only one of them (#9 and #10) will be 1. The another will be 0.
      feature9 <- BedroomBedMatrixIndexes(secondHighestTempIndex)
      feature10 <- BedroomFloorMatrixIndexes(secondHighestTempIndex)
      
      # Defines a machine learning text line (one example with its features and class)
      auxString <- paste(toString(specify_decimal(feature1, 1)), ",", sep="") # feature 1
      auxString <- paste(auxString, toString(feature2), sep="") # feature 2
      auxString <- paste(auxString, ",", sep="")
      auxString <- paste(auxString, toString(feature3), sep="")  # feature 3
      auxString <- paste(auxString, ",", sep="")
      auxString <- paste(auxString, toString(specify_decimal(feature4, 1)), sep="")  # feature 4
      auxString <- paste(auxString, ",", sep="")
      auxString <- paste(auxString, toString(specify_decimal(feature5, 1)), sep="")  # feature 5
      auxString <- paste(auxString, ",", sep="")
      auxString <- paste(auxString, toString(specify_decimal(feature6, 1)), sep="")  # feature 6
      auxString <- paste(auxString, ",", sep="")
      auxString <- paste(auxString, toString(feature7), sep="") # feature 7
      auxString <- paste(auxString, ",", sep="")
      auxString <- paste(auxString, toString(feature8), sep="") # feature 8
      auxString <- paste(auxString, ",", sep="")
      auxString <- paste(auxString, toString(feature9), sep="") # feature 9
      auxString <- paste(auxString, ",", sep="")
      auxString <- paste(auxString, toString(feature10), sep="") # feature 10
      auxString <- paste(auxString, ",", sep="")

      auxString <- paste(auxString, stringClass, sep="") # class
      auxString <- trim(auxString)  
      
    } # Closes it will add all features
    
    
    # Add the current machine learning example to all machine learning examples list (dataset)
    machineLearningData <- c(machineLearningData, auxString) # add it to dataset
  } # Closes for(i in 1:nrow(thermalDataFrame))
  
  #auxDataFrame <- thermalDataFrame[2:17]
  #auxDataFrame["PostureClass"] <- postureClass
  # Converts the first column in integer for not writing the number between ""
  #auxDataFrame[, 1] <- as.integer(as.character(auxDataFrame[, 1]))
  
  # volunteer/posture dataset text file. over writes it every time the program runs
  # text file name is passed through function parameter
  write.table(machineLearningData, machineLearningFile, row.names = FALSE, col.names = FALSE, quote = FALSE)
  # append previous dataset text files
  # text file name is defined at the beggining of this function
  write.table(machineLearningData, arffDataFile, row.names = FALSE, col.names = FALSE, quote = FALSE, append = TRUE)
  
  close(machineLearningFile)
  close(arffDataFile)
  
  return(machineLearningData)
  
}

# returns string w/o leading or trailing whitespace
trim <- function (x) gsub("^\\s+|\\s+$", "", x)

specify_decimal <- function(x, k) format(round(x, k), nsmall=k)


# -------------------------- M A I N --------------------------------------------

# You need to update the string below with the .csv file that contains the recorded thermal data (dataset files)
filePathRecordedThermalData = "X.csv" 

recordedThermalData = read.csv(filePathRecordedThermalData, header = TRUE, sep = ",", skip = 1)

# Removes the last row for processing only the thermal data
recordedThermalData <- recordedThermalData[-c(nrow(recordedThermalData)), ]

# You need to update the string below with a .txt path file to be created. This .txt file will contain the machine learning features and
# respective class of the current thermal data (variable recordedThermalData).
filePathMLFile = "Y.txt"

# You need to update the string below with a .txt path file to be created or appended. This .txt file will contain the machine learning features and
# respective class of all thermal data files, so you need to call the function writeMachineLearningTextFile more than one time,
# with different recordedThermalData, to append the data to wekaInputFilePath.
wekaInputFilePath = "Z.txt"

# The line below is an example of calling the function that process recordedThermalData (third parameter) 
# to generate filePath (second parameter) and append its results to wekaInputFile (last parameter). The input data of this process 
# is the raw sensor OMRON D6T-44L data (4x4 field of view temperatures + ambient temperature) and its class name (first parameter).
# The fourth parameter (featureSelection) should be TRUE when not all features are desired, there is an if statement for setting up 
# the features you want inside writeMachineLearningTextFile function. If featureSelection is FALSE, the output data will contain all features. 
writeMachineLearningTextFile <- function(stringClass, filePath, thermalDataFrame, featureSelection, wekaInputFile){
mlData <- writeMachineLearningTextFile("EmPe", filePathMLFile, recordedThermalData, FALSE, wekaInputFilePath) 


