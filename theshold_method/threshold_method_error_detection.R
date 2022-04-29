
###############################################
# this script detects sudden jumps in F0 
# which are likely to be F0 measurement errors. 

# created by:  Jeremy Steffman 
# last updated: April 29, 2022
##############################################

### required input: 
# long format data with the following columns 
# -F0 in semitones
# -time in ms (can be at any interval, e.g., 1ms, 10ms, 100ms)
# -a column which uniquely identifies each trajectory
# -an optional column that contains speaker information. 

### output 
# - an annotated data frame which flags all sample to sample errors
# - a summary of flagged errors by unique identifier
# - a summary of flagged errors by unique identifier ONLY for files which were flagged as errors
# - a summary of errors by speaker, if the speaker column is specified 


# this package required: 
library(tidyverse)
# if not installed, use the following: install.packages("tidyverse")

# load in data here
setwd(dirname(rstudioapi::getActiveDocumentContext()$path))
data<-read.csv("example10speakers.csv") # change to be your data name

### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### 
#### SET THESE PARAMETERS #############################################
# (1) input the sampling rate of your F0 measures in milliseconds 
time_step_ms = 10 
## variable names
# input the names of the required variables in your data frame
# (2) name of F0 (in semitones): replace YOUR_VARIABLE_NAME_HERE with your variable
data$F0_semitones <- data$YOUR_VARIABLE_NAME_HERE 
# (3) name of variable that identifies each unique trajectory
data$uniqueID <- data$YOUR_VARIABLE_NAME_HERE
# (3) name of variable that identifies time, in milliseconds
data$t_ms <- data$YOUR_VARIABLE_NAME_HERE
# (3) name of variable that identifies speaker, for optional speaker summary stats
data$speaker <- data$YOUR_VARIABLE_NAME_HERE  

#### ADJUST THESE THRESHOLDS IF DESIRED #### 
# from Sundberg (1973), for 10 ms temporal intervals and female speakers
rise_threshold = 1.2631578947
fall_threshold = 1.7142857143
#######################################################################
### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ###

## run the rest of the scrip to annotate the data frame and  the save the outputs

time_mutation = time_step_ms/10

data %>% group_by(uniqueID) %>%  
  mutate(lead_F0_semitones= lead(F0_semitones, order_by=t_ms),
        diff = lead_F0_semitones-F0_semitones,
        err = ifelse(diff>0&(abs(diff)*time_mutation)>rise_threshold,1,
              ifelse(diff<0&(abs(diff)*time_mutation)>fall_threshold,1,0)),
        err_prop_by_ID = mean(err,na.rm = T),
        err_count_by_ID = sum(err,na.rm = T),
        err_in_ID=ifelse(err_prop_by_ID>0,1,0)) -> data_annotated

data_annotated %>% 
  group_by(uniqueID) %>% 
  select(uniqueID,err_prop_by_ID,err_count_by_ID,err_in_ID) %>% slice(1) -> data_summary_by_ID

data_summary_by_ID %>% filter(err_in_ID==1) %>% 
  select(-err_in_ID) ->data_summary_by_ID_errors_only

data_annotated %>% group_by(speaker) %>% 
  mutate(err_prop_by_speaker = mean(err,na.rm = T), 
         err_count_by_speaker = sum(err,na.rm = T)) %>% 
  select(speaker,err_count_by_speaker,err_prop_by_speaker) %>% slice(1) -> data_summary_by_speaker
  

write.csv(data_summary_by_speaker,file="output_files/data_summary_by_speaker.csv")
write.csv(data_summary_by_ID,file="output_files/data_summary_by_ID.csv")
write.csv(data_summary_by_ID_errors_only,file="output_files/data_summary_by_ID_errors_only.csv")
write.csv(data_annotated,file="output_files/data_annotated.csv")



