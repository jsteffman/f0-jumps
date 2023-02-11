
###############################################
# this script detects sudden jumps in F0 
# which are likely to be F0 measurement errors. 

# created by:  Jeremy Steffman 
# last updated: November 16, 2022
##############################################

### required input: 
# long format data with the following columns 
# -F0 in semitones (can be converted from Hz in R using this function): 
# https://search.r-project.org/CRAN/refmans/hqmisc/html/f2st.html
# -time in ms (can be at any interval, e.g., 1ms, 10ms, 100ms)
# -a column which uniquely identifies each trajectory
# -an optional column that contains speaker information. 

### output 
# - an annotated data frame which flags all sample to sample errors
# - a summary of flagged errors by unique identifier
# - a summary of flagged errors by unique identifier ONLY for files which were flagged as errors
# - a summary of errors by speaker, if the speaker column is specified 
# descriptions of the annotated columns are given at the end of the script. 

# this package required: 
library(tidyverse)
# if not installed, use the following: install.packages("tidyverse")

# load in data here
setwd(dirname(rstudioapi::getActiveDocumentContext()$path))
data<-read.csv("example10speakers.csv") # change to be your data

### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### 
#### SET THESE PARAMETERS #############################################
# (1) input the sampling rate of your F0 measures in milliseconds 
time_step_ms = 10 
## variable names
# input the names of the required variables in your data frame
# (2) name of the column containing F0 (in semitones, and Hz): replace YOUR_VARIABLE_NAME_HERE with your variable
data$F0_semitones <- data$F0_semitones 
data$F0_Hz<-data$F0_Hz
# (3) name of variable that identifies each unique trajectory
data$uniqueID <- data$uniqueID
# (3) name of variable that identifies time, in milliseconds
data$t_ms <- data$t_ms
# (3) name of variable that identifies speaker, for optional speaker summary statistics
data$speaker <- data$speaker  

#### ADJUST THESE THRESHOLDS IF DESIRED #### 
# from Sundberg (1973), for 10 ms temporal intervals and female speakers
rise_threshold = 1.2631578947
fall_threshold = 1.7142857143
#######################################################################
### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ###

## Run the rest of the scrip to annotate the data frame and  the save the outputs

time_mutation = time_step_ms/10

data %>% group_by(uniqueID) %>%  
  mutate(lead_F0_semitones= lead(F0_semitones, order_by=t_ms),
         lead_F0_Hz= lead(F0_Hz, order_by=t_ms),
        diff = lead_F0_semitones-F0_semitones,
        time_diff = lead(t_ms) - t_ms,
        ratio_Hz = lead_F0_Hz/F0_Hz,
        oct_jump = ifelse(ratio_Hz<0.49|ratio_Hz>1.99,1,0), # halving and doubling ratios for octave jump detection
        err = ifelse(time_diff > time_step_ms,0, ## this ignore time differences larger than the time step, e.g., over voiceless intervals. 
              ifelse(diff>0&(abs(diff)*time_mutation)>rise_threshold,1,
              ifelse(diff<0&(abs(diff)*time_mutation)>fall_threshold,1,0))),
        err_prop_by_ID = mean(err,na.rm = T),
        err_count_by_ID = sum(err,na.rm = T),
        err_in_ID=ifelse(err_prop_by_ID>0,1,0),
        time_of_err = ifelse(err_in_ID==1&err==1,t_ms,0), 
        F0_of_err = ifelse(lag(err)==1,F0_semitones,0),
        # compute octave jumps
        oct_jump_prop_by_ID = mean(oct_jump,na.rm = T),
        oct_jump_count_by_ID = sum(oct_jump,na.rm = T),
        oct_jump_in_ID= ifelse(oct_jump_prop_by_ID>0,1,0)) %>% 
      mutate_if(is.numeric, ~replace(., is.na(.), 0))-> data_annotated

# The following part of the script computes "carryover errors". These are errors for which the sample to sample difference does not necessarily exceed the threshold by the specified amount, but they are within one threshold's worth of the first inaccurate F0 value and are temporally adjacent to it. It is important to emphasize that these *may not be errors*, but  can inspected, for e.g., pitch doubling which raises a whole string of values to be inaccurate. 


data_annotated %>% group_by(uniqueID) %>% 
  mutate(nrow=n(),
         carryover_err_start = ifelse(lag(err)==1,1,0),
         carryover_err = carryover_err_start) ->data_annotated

x1 =1
repeat {
  data_annotated %>% group_by(uniqueID) %>% 
    mutate(F0_of_err=ifelse(F0_of_err == 0,lag(F0_of_err,order_by = t_ms),F0_of_err)) -> data_annotated
  
  x1 = x1+1
  print(paste0(round(x1/max(data_annotated$nrow)*100,0), "% done"))
  if (x1 == max(data_annotated$nrow)){  
    break
  }
}


data_annotated$F0_of_err[is.na(data_annotated$F0_of_err)] <- 0

x2=1
repeat {
  data_annotated %>% group_by(uniqueID) %>% 
  mutate(carryover_err = 
       ifelse(lag(carryover_err)==1& 
              (lead(F0_semitones)>F0_semitones)& 
              abs(F0_semitones-F0_of_err)<rise_threshold*1.5|
             lag(carryover_err)==1&
            (lead(F0_semitones)<F0_semitones)& 
          abs(F0_semitones-F0_of_err)<fall_threshold*1.5,1,carryover_err))-> data_annotated
  x2 = x2+1
  print(paste0(round(x2/max(data_annotated$nrow)*100,0), "% done"))
  if (x2 == max(data_annotated$nrow)){  
    break
             }
}


data_annotated$carryover_err[is.na(data_annotated$carryover_err)] <- 0

data_annotated %>% group_by(uniqueID) %>% 
  mutate(carryover_err = ifelse(t_ms==max(t_ms)&lag(carryover_err)==1,1,carryover_err),
         flagged_samples = carryover_err,
        # flagged_samples includes the seeding samples for carryover error detection- i.e. some actual errors
         carryover_only = ifelse(err==1,0,carryover_err),
        prop_carryover_err= mean(carryover_only)) -> data_annotated
# carryover_only includes only carry over errors


data_annotated %>% select(-nrow,-carryover_err_start,-carryover_err) -> data_annotated
  
mean(data_annotated$err_in_ID)

data_annotated %>% 
  group_by(uniqueID) %>% 
  select(uniqueID,err_prop_by_ID,err_count_by_ID,err_in_ID,
         oct_jump_prop_by_ID,oct_jump_count_by_ID,oct_jump_in_ID
         ) %>% slice(1) -> data_summary_by_ID

data_summary_by_ID %>% filter(err_in_ID==1) %>% 
  select(-err_in_ID) ->data_summary_by_ID_errors_only

data_annotated %>% group_by(speaker) %>% 
  mutate(err_prop_by_speaker = mean(err,na.rm = T), 
         err_count_by_speaker = sum(err,na.rm = T)) %>% 
  select(speaker,err_count_by_speaker,err_prop_by_speaker) %>% slice(1) -> data_summary_by_speaker
  
# save files as csv - EXISTING FILES WILL BE OVERWRITTEN
write.csv(data_summary_by_speaker,file="output_files/data_summary_by_speaker.csv")
write.csv(data_summary_by_ID,file="output_files/data_summary_by_ID.csv")
write.csv(data_summary_by_ID_errors_only,file="output_files/data_summary_by_ID_errors_only.csv")
write.csv(data_annotated,file="output_files/data_annotated.csv")

## here is an example of how to exclude trajectories/samples with errors in them 
data_annotated %>% filter(err_in_ID==0) -> data_annotated_errs_removed1
# the above removes all trajectories that have any errors in them. 
data_annotated %>% filter(flagged_samples==0) -> data_annotated_errs_removed2
# and this removes just suspect samples from the data 

### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### 
# In the OUTPUTs the following columns are added, for analysis/exclusion of files #
### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### 

## oct_jump: does this sample-to-sample difference constitute an octave jump?
## err: does this sample-to-sample difference exceed the set thresholds. 
## err_prop_by_ID: the prop. of sample-to-sample diffs that exceed the threshold for this trajectory
## err_count_by_ID: the count of sample-to-sample diffs that exceed the threshold for this trajectory
## err_in_ID: whether or not there is ANY sample-to-sample diff that exceeds the threshold for the trajectory. 
## oct_jump_prop_by_ID: the prop. of octave jumps for this trajectory
## oct_jump_count_by_ID: the count of octave jumps for this trajectory
## err_in_ID: whether or not there is ANY octave jump in the trajectory
## time_of_err: the time (in ms) where a sample-to-sample jump occurs
## F0_of_err: the F0 value (in semitones) where an error is flagged based on the threshold. ## carryover_only: if a sample is a carryover error; one which does not exceed the threshold, but is within a threshold of a preceding error. See the paper that accompanies this script, here: https://asa.scitation.org/doi/10.1121/10.0015045 and the image illustrating carryover errors, here: https://osf.io/ms8za for explanation. 
## prop_carryover_error: the prop. of carryover errors in a trajectory. 
## flagged_samples: Whether a sample is flagged, either by virtue of exceeding the threshold, or being a carryover error, i.e. all suspect samples. 

