# Thermal Sensing Data Classification Research
  This repository contains the collected dataset, and developed source code in the research "Human-Sensing: Low Resolution Thermal Array Sensor Data Classification of Location-Based Postures", which will be published at the 5th International Conference on Distributed, Ambient and Pervasive Interactions. 

## Abstract
  Ambient Assisted Living (AAL) applications aim to allow elderly, sick and disabled people to stay safely at home while collaboratively assisted by their family, friends and medical staff. AAL, recently empowered by the Internet of Things, introduces a new healthcare connectivity paradigm that interconnects mobile apps and sensors allowing constant monitoring of the patient. Preserving privacy in the course of recognition of postures and classification of activities is one of the challenges for human-sensing and a critical factor of user acceptance, so there is a demand for solutions that do not require real live imaging in AAL.
  This paper addresses this challenge through the usage of a low resolution ther- mal sensor and machine learning techniques, discussing the feasibility of low cost and privacy protecting solutions. We evaluated decision tree models in two tasks of human-sensing, presence and posture recognition, using data of different days and volunteers. We also contribute by providing public domain datasets, collected in a bedroom and a bathroom, which are described in this paper.
  
## Keywords
Household Monitoring, Human-Sensing, Machine Learning, Privacy, Thermal Sensors, Low Resolution.

# Repository
## Code-Arduino
This program reads OMRON D6T-44L sensor data and sends it via serial port. 

## Code-Processing
This program communicates to the Arduino program, label each temperatures' matrix and persists it in a text file. This program also shows the temperatures on a 4x4 matrix layout. 

## Code-R
The program developed in R reads the labeled text files, that contains the raw temperatures' matrix data from OMRON D6T-44L, pre processes it extracting some features, and outputs text files in order to generate/validate machine learning models. 

## Dataset
Inside Dataset folder there are 8 folders from 7 different days of data collection. Each of these folders contains .csv files with the collected thermal data.

## CSV file name structure
Pending.
