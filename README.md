# f0-jumps
If you've worked with time-series f0 measurements, you know that sudden discontinuities in f0, due to consonantal junctures, non-modal phonation etc., are quite common. 
Maybe you want to identify places where these occur in order to exlude files from your analysis which show innacurate f0 measures. 
Maybe you're curious about the files with sudden jumps and want to inspect them. 
Either way, this R script will help you identify f0 halving/doubling in a time series f0 measurement. 
The input is a data frame with (at least) three columns, one for time, one for f0 and one for a filename. 
The output is an annoatated file which identifies sample-to-sample difference in f0 which are halved or doubled. 
And idenfication of files which have these events in them. 
The thresholds for what counts as f0 halving/doubling are adjustable. 
