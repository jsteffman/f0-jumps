## created by Jeremy Steffman 
## last updated 11-27-21
##########################################################################################
## This script detects F0 jumps which exceed a particular threshold in semitones. Some thresholds from papers document rate of F0-change are included, but these can be customized.
## A particular data frame structure is required, see below. 
## commented lines below explain each step. 
## save files are put into the "output" folder. 
##########################################################################################

### REQUIRES THESE PACKAGES ###############################################################
#install.packages("tidyverse") # uncomment and run if needed
#install.packages("hqmisc") # uncomment and run if needed
#########################################################################################
library(tidyverse);library(hqmisc)
setwd(dirname(rstudioapi::getActiveDocumentContext()$path)) # set working directory to the folder this script is in- 

###  demo data here## 
data<-read.csv("demo_data.csv",sep = ",") # change filepath as needed- if you don't run line 14 above 
## note that this particular data set has many f0-jumps it includes measurements accross word boundaries over an utterance- you can probably expect jumps to be fewer in number for a sonorant-only within-word measure. 

##########################################################################################
# THIS SCRIPT ASSUMES that there are columns called (1) "Filename" (2) "t_ms" and (3) "F0" 
## Filename must uniquely identify each F0 trajectory of interest. These are just numbers in the example file. 
## t_ms should be a time-series. 
## F0 should be measured F0 in Hz, at each time. THIS SCRIPT ASSUMES 10 ms time steps, though this can be adjusted. 
##########################################################################################

# compute semitones from Hz, with 100 Hz baseline
data<-data %>%mutate(ST=f2st(F0,base=100))

# set thresholds for what counts as "too fast" of a rise or fall
# These thresholds are from the non-singer female speakers in Sundberg (1973), who produced glissandos as quickly as possible. They are thus a fairly reasonable upper limit on how fast humans should be able to produce f0 changes (n.b. females were on aggregate faster than males in that study). 

# citation: Sundberg, J. (1973). Data on maximum speed of pitch changes. Speech transmission laboratory quarterly progress and status report, 4, 39-47.

risethreshold = 1.2631578947
# from 12 ST in 95 ms
fallthreshold = -1.7142857143
# from 12 ST in 70 ms

data<-data %>%
  group_by(Filename) %>%  
  mutate(lead_ST= lead(ST, order_by=t_ms),
         ST_diff = lead_ST-ST,
         ST_jump = ifelse(ST_diff>risethreshold|
                         ST_diff<fallthreshold,1,0), # compute if sampel to sample diffs exceed threshold for every pair of samples
         ST_jump_trial_mean = mean(ST_jump,na.rm = T), # mean number samples with jumps per file
         ST_jump_count = sum(ST_jump,na.rm = T), # number of jumps in a file
         ST_jump_in_trial=ifelse(ST_jump_trial_mean>0,1,0))  # 1 if there are any jumps in the file



error_summary<- data %>% group_by(Filename) %>% select(ST_jump_trial_mean,ST_jump_count,ST_jump_in_trial, Filename) %>%  slice(1)      # summary by Filename
  
mean(error_summary$ST_jump_in_trial)
  

# save files as csv if desired 
write_csv(data,"output/annotated_data_semitones.csv") # the full data set 
write_csv(error_summary,"output/file_list_semitones.csv") # list of file names that have doubling or halving 


