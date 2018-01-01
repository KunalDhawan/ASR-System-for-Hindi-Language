#!/bin/csh
#-----------------------------------------------------------------------------
# NAME OF THE FILE 	       : hvite.sh
# PURPOSE		       : Shell script for recognition of feature files 
#			          using HTK (ver2.2) Tool HVite
#          To test on new data, change TEST_SCP and RECOUT_MLF_FILE.
# IMPLICIT INPUT  VARIABLES    : HMM definition file, configuration file,
#                                 dictionary, hmmlist
# IMPLICIT OUTPUT VARIABLES    : Macro label file.
# CALLED FUNCTIONS	       : HTK V2.0 tool HVite.
#-----------------------------------------------------------------------------

#set penalty = $1
foreach ff ($HMMDEFS $MACROS $TEST_SCP $FINAL_DICT $SYMBOL_LIST)
    if (! -e $ff) then
	echo " Sorry\! $ff does not exist."
	echo " Program aborted."
	exit 1
    endif
end

#recognition using test/train databases
HVite \
#  -f      		#output full state alignment	\
  -i $RECOUT_MLF	#store output labels in mlf file. \
  -p 0.0		\
  -s 5.0		\
  -w lm/wordent_bigram	\
  -l '*'		\
  -A                     #print command line arguments. \
  -H $HMMDEFS            #hmm monophone models. \
  -H $MACROS             \
  -S $TEST_SCP           #file containing list of feature files  \
  -T 1			\
  $FINAL_DICT            #Dictionary with word pronunciations. \
  $SYMBOL_LIST           #hmm symbol list.

#  -w lm/bglm		\

HResults \
  -I $REF_WORD_MLF	\
  $SYMBOL_LIST          #hmm symbol list	\
  $RECOUT_MLF		#output of recogniser in mlf file.

echo "----------------- End of hvite.csh -----------------"

