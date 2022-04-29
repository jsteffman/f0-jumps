# f0-jumps
If you've worked with time-series f0 measurements, you know that sudden discontinuities in f0, due to consonantal junctures, non-modal phonation etc., are quite common. 
Maybe you want to identify places where these occur in order to exclude files or samples from your analysis which show innaccurate f0 measures. 
Maybe you're curious about the files with sudden jumps and want to inspect them. 
Either way, these R scripts will help you identify f0 jumps in a time series f0 measurement. There are currently two versions.

-halving_doubling_detector.R : computes if pitch halving or doubling has occurred based on the ratio of adjacent f0 samples

The input is a data frame with (at least) three columns, one for time, one for f0 and one for a filename. 
The output is an annotated file which identifies sample-to-sample difference in f0 which are halved or doubled, or exceed set thresholds. 
And identification of files which have these events in them. 

-threshold_method.R : computes if a sample-to-sample difference exceeds a set threshold in semitones, with the default threshold coming from a study on the maximum rate of f0 change that humans can produce. the script contains details on the required input and outputs. 

The thresholds for both versions are adjustable. 
