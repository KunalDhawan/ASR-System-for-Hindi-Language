#!/bin/csh
#-----------------------------------------------------------------------------
# NAME OF THE FILE 	: hviteAlign.sh
# PURPOSE		: Shell script for re-alignment of training files;
#                         Uses multiple pronunciations and generates optimal
#                         phone transcriptions for training features files.
#			  HTK (ver2.2) Tool HVite
# INPUT ARGUMENTS	: None.
# OUTPUT ARGUMENTS	: None.
# IN and OUT ARGS	: None.
# IMPLICIT INPUT  VARIABLES: HMM definition files, word transcription file,
#			     directory name, configuration 
#			     file,  dictionary, hmmlist
# IMPLICIT OUTPUT VARIABLES: Macro label file containing time alignment.
# IMPLICIT IN and OUT VARIABLES: None.
# CALLED FUNCTIONS	: HTK V2.2 tool HVite.
#-----------------------------------------------------------------------------

# if the required files do not exist, then abort.
foreach ff ($CONFIG $FINAL_DICT $SYMBOL_LIST )
    if (! -e $ff) then 
	echo " Sorry\! $ff does not exist."
	echo " Program aborted."
	exit 1
    endif
end

# Note the use of "HVite -a" here to generate forced alignments :
HVite	\
  -a			# generate time-alignment of labels with waveform.\
  -b sil                # include silence at begin/end of utterance \
  -i lm/${TASK}Aligned.mlf # OUTPUT:store aligned transcription in this MLF file \
  -m			# retain symbol boundaries (time-alignment)\
  -o SWT		# Do NOT output segment scores and word labels.\
  -y lab        \
  -A \
  -C $CONFIG            # $TARGET_KIND \
  -H hmm/hmm7/hmmdefs   # search $SRCHMM7/hmmdefs for HMM definition files.\
  -H hmm/hmm7/macros    # load $SRCHMM7/macros as HMM definition files.\
  -I lm/${TASK}Word.mlf	# word level transcription MLF file \
  -S $FEATURE_SCRIPT	# a list of all feature files. \
  -T 1		        # set trace level to 1.\
  $FINAL_DICT           # Dictionary: word  phone_transcription. \
  $SYMBOL_LIST		# list of hmm(symbol)s.

echo "------------------------- End of hviteAlign.sh ------------------------"
exit 0
