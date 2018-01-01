#!/bin/csh
#-----------------------------------------------------------------------------
# NAME OF THE FILE   	: hcopy.csh
# PURPOSE		: Feature extraction from wav data 
#			  files using HTK (ver2.0) Tool HCopy
# INPUT ARGUMENTS	: none
# OUTPUT ARGUMENTS      : none
# IMPLICIT INPUT  VARIABLES: configuration file (feature extraction)
# IMPLICIT OUTPUT VARIABLES: feature files.
# CALLED FUNCTIONS	: HCopy (HTK V2.2)
# STEP 5 in HTK Tutorial
#-----------------------------------------------------------------------------
date
alias rmtouch		'if (-e \!*) rm \!*; touch \!*'
# Make a list of (input wave files, output feature files)
rmtouch htk_files/hcopy_script.txt
#Make a list the .wav files under data directory
find data/train/ -name '*.wav' |  \
	perl -ne 'chomp; $_ =~ /(.+)\.wav/; print "$_ $1.mfc\n"' >> htk_files/hcopy_script.txt

# Extract features from wave files.
if (! -d log) mkdir log
rmtouch log/hcopy.log
HCopy	        \
  -A                  \
  -C $CONFIG		# INPUT: feature extraction config file \
  -S htk_files/hcopy_script.txt	# list of (input wave files, output feature files)\
  -T 1		# tracing \
  >> log/hcopy.log

echo "--------------------- End of hcopy.csh ---------------------------"
date
exit

