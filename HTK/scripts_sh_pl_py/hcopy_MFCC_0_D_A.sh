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
# STEP 5 in HTK Tutorial	for recognition

#-----------------------------------------------------------------------------
date
alias rmtouch		'if (-e \!*) rm \!*; touch \!*'
# Make a list of (input wave files, output feature files)
rmtouch htk_files/test_script.txt
find data/test/ -name '*.wav' |  \
	perl -ne 'chomp; $_ =~ /(.+)\.wav/; print "$_ $1.mfc_D_A\n"' >> htk_files/test_script.txt

# Extract features from wave files.
rmtouch log/test.log
  HCopy	        \
    -A                  \
    -C htk_files/configs  # INPUT: feature extraction config file \
#  -C htk_files/configs_demo_MFCC12_0_Z_D_A  # INPUT: feature extraction config file \
    -S htk_files/test_script.txt	# list of (input wave files, output feature files)\
    -T 1		# tracing \
    >> log/test.log

echo "--------------------- End of hcopy.csh ---------------------------"

date
exit
