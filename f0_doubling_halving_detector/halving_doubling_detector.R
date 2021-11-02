## created by Jeremy Steffman 
## last updated 11-2-21
##########################################################################################
## This script detects halving/doubling in F0 time-series measures, where you can set what ratios of adjacent sample values count as halving and doubling. The script will then annotate the file of interest, and create a file list those files containing halving/doubling errors.
## A particular data frame structure is required, see below. 
## commented lines below explain each step. 
## save files are put into the "output" folder. 
##########################################################################################

### REQUIRES THIS PACKAGE ###############################################################
#install.packages("tidyverse") # uncomment and run if needed
#########################################################################################
library(tidyverse)
setwd(dirname(rstudioapi::getActiveDocumentContext()$path)) # set working directory to the folder this script is in- 

###  demo data here## 
data<-read.csv("demo_data.csv",sep = ",") # change filepath as needed- if you don't run line 14 above 
##########################################################################################
# THIS SCRIPT ASSUMES that there are columns called (1) "Filename" (2) "t_ms" and (3) "F0" 
## Filename must uniquely identify each F0 trajectory of interest. These are just numbers in the example file. 
## t_ms should be a time-series. 
## F0 should be measured F0, at each time. 
##########################################################################################


data<-data %>%
  group_by(Filename) %>%  
  mutate(lead_F0= lead(F0, order_by=t_ms),
         ratio = lead_F0/F0, 
         halving = ifelse(0.52>ratio&ratio>0.48,1,0), # change 0.52/0.48 to adjust what range of ratios count as halving.  1 in the output means halving has occured. 
         doubling = ifelse(2.02>ratio&ratio>1.98,1,0), # change 2.02/1.98 to adjust what range of ratios count as doubling. 1 in the output means doubling has occured. 
         prose =ifelse(halving==1,"halving",ifelse(doubling==1,"doubling","neither")), # this column just says whether halving double or neither has happened for sample and the sample that follows it. 
         halving_mean = mean(halving,na.rm = TRUE), # prop. samples which halve/double
         doubling_mean= mean(doubling,na.rm = TRUE),
         halving_in_file=ifelse(halving_mean>0,1,0), # 1 if any samples in file halve, 0 otherwise
         doubling_in_file=ifelse(doubling_mean>0,1,0))# 1 if any samples in file double, 0 otherwise

data %>% filter(halving_in_file==1|doubling_in_file==1) -> files_with_doubling_halving
# just files with either doubling or halving 
file_list<-as.data.frame(unique(files_with_doubling_halving$Filename));colnames(file_list)<-"Filename" # this is a list of filenames for files that have either doubling or halving 

# save files as csv if desired 
write_csv(data,"output/annotated_data.csv") # the full data set 
write_csv(files_with_doubling_halving,"output/annotated_data_with_doubling_halving.csv") # just the files with doubling or halving
write_csv(file_list,"output/file_list.csv") # list of file names that have doubling or halving 


