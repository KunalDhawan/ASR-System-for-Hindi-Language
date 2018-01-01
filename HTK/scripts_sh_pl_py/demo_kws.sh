#!/bin/csh
#-----------------------------------------------------------------------------
# NAME OF THE FILE 	       : demo_kws.sh
# PURPOSE		       : Shell script for recognition of feature files 
#			          using HTK (ver2.2) Tool HVite
#          To test on new data, change TEST_SCP and RECOUT_MLF_FILE.
# IMPLICIT INPUT  VARIABLES    : HMM definition file, configuration file,
#                                 dictionary, hmmlist
# IMPLICIT OUTPUT VARIABLES    : Macro label file.
# CALLED FUNCTIONS	       : HTK V2.0 tool HVite.
#-----------------------------------------------------------------------------

foreach ff ($HMMDEFS $MACROS $FINAL_DICT $SYMBOL_LIST)
    if (! -e $ff) then
	echo " Sorry\! $ff does not exist."
	echo " Program aborted."
	exit 1
    endif
end

# record test data for 6 seconds
echo -n "Press enter and then speak a sequence of digits within 6 seconds:"
set start = $<
rec -r 16000 -b 16 -c 1 demo.wav trim 0 6
#cp data/wav17_KA_001/KA001M0020.wav demo.wav

# Compute features
  HCopy	        \
    -C htk_files/configs_demo_MFCC12_0_Z_D_A # INPUT: feature extraction config file \
     demo.wav demo.mfc

#recognition of demo file
HVite \
#  -f      		#output full state alignment	\
#  -i $RECOUT_MLF	#store output labels in mlf file. \
  -p -10		# word insertion penalty\
  -r 0.5		# dictionary probability scale factor \
  -s 10.0		# grammar scale factor \
#  -w lm/bglm		\
  -w lm/wdnet_kws.txt	\
#  -l '*'		\
  -A                    #print command line arguments. \
  -H $HMMDEFS            #hmm monophone models. \
  -H $MACROS             \
#  -S $TEST_SCP           #file containing list of feature files  \
  -T 2			\
  $FINAL_DICT            #Dictionary with word pronunciations. \
  $SYMBOL_LIST           #hmm symbol list.	\
  demo.mfc

cat demo.rec

exit

