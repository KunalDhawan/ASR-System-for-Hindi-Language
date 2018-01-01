#!/bin/csh
#-----------------------------------------------------------------------------
# NAME OF THE FILE   	: hcopy_MFCC12_D_A_0_Z.sh
# PURPOSE		: Feature extraction from wav data 
#			  files using HTK (ver2.0) Tool HCopy
# INPUT ARGUMENTS	: none
# OUTPUT ARGUMENTS      : none
# IMPLICIT INPUT  VARIABLES: configuration file (feature extraction)
# IMPLICIT OUTPUT VARIABLES: feature files.
# CALLED FUNCTIONS	: HCopy (HTK V2.2)
# Recognise all data under wav directory  (test === TRAINING data).
# For recognition, compute delta,delta-delta too	

#-----------------------------------------------------------------------------
date
alias rmtouch		'if (-e \!*) rm \!*; touch \!*'
# Make a list of (input wave files, output feature files)
rmtouch htk_files/test_hcopy_script.txt
find data/test/ -name '*.wav' |  \
	perl -ne 'chomp; $_ =~ /(.+)\.wav/; print "$_ $1.mfc_D_A\n"' >> \
		htk_files/test_hcopy_script.txt
rmtouch $TEST_SCP
perl -nae 'print "@F[1]\n"' htk_files/test_hcopy_script.txt >> $TEST_SCP

# Extract features from wave files.
rmtouch log/test_hcopy.log
HCopy	        	\
  -A			\
  -C $CONFIG 		# INPUT: feature extraction config file \
  -S htk_files/test_hcopy_script.txt	# list of (input wave files, output feature files)\
    -T 1		# tracing \
    >> log/test_hcopy.log

echo "---------------- End of hcopy_MFCC12_D_A_0_Z.sh -----------------------"
date
exit
