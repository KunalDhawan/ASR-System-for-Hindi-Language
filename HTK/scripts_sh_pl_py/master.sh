#!/bin/csh
#-----------------------------------------------------------------------------
# NAME OF THE FILE 	: master.sh
# PURPOSE		: Shell script to conduct number recognition expts.
# INPUT ARGUMENTS	: one argument: denotes the stage where processing
#                         is to start/resume. 
# OUTPUT ARGUMENTS	: None.
# IMPLICIT INPUT  VARIABLES     : {configuration, label editor,..} files.
# IMPLICIT OUTPUT VARIABLES     : label directories, etc.
# IMPLICIT IN and OUT VARIABLES : none.
# CALLED FUNCTION:         hcopy.sh, hparse.sh, proto.sh, hcompv.sh, herest.sh,
#			  hhedSil.sh, heAdapt.sh, hvite.sh, hresults.sh.
#-----------------------------------------------------------------------------

if ($#argv == 0) then
  echo "\n Atleast one parameter is expected\n"
  echo "Usage : $0 {HCOPY | LEXICON | HCOMPV | HEADAPT}"
  exit 1
endif

setenv LANGUAGE		hi
setenv TASK		hindi_word_reco
# setenv HTK_HOME 	~/${TASK}_$LANGUAGE
setenv HTK_HOME 	~/hindi-monophone-recog-23-12-17
cd $HTK_HOME

alias rmtouch		'if (-e \!*) rm \!*; touch \!*' # removes old file having the same name and creates an empty file
setenv CONFIG		htk_files/configs_MFCC12_D_A_0_Z
setenv FEATURE_SCRIPT	htk_files/hcompv_script.txt
setenv DICT 		lm/lexicon.txt
setenv FINAL_DICT	lm/sorted.lexicon.txt
setenv PHONE_MLF	lm/${TASK}Phone0.mlf
setenv SYMBOL_LIST	lm/monophones1

goto $1


HCOPY:
# hcopy.sh takes the wave files as input and parametrises 
# them into corresponding feature (ex: Mel Frequency Coefficient) files  
# using a proper configuration file. This will be used to develop a speaker
# independent speech recognition system.
setenv CONFIG		htk_files/configs_hcopyMFCC12_0_Z
scripts_sh_pl_py/hcopy.sh
exit

LEXICON:
# Generate [in lm directory] files containing 
#   transcriptions
#   Master Label Files at phone level and word level
#   Bigram grammar files
#   lists of symbols (monophones0 and monophones1)
rmtouch log/lexicon.log
scripts_sh_pl_py/writeTranscriptions.sh
scripts_sh_pl_py/create_lm.sh >> log/lexicon.log
exit

HCOMPV:		#	Step 6 of HTK tutorial on Chapter 3
# Create directories to hold various versions of HMMs.
if (-d hmm) rm -rf hmm;
mkdir hmm
foreach n (0 1 2 3 4 5 6 7 8 9)
  mkdir hmm/hmm$n
end
# Use all training files to compute global means & variances of features.
# Set the means & variances of all state pdfs of the prototype HMM
#   to equal to the global ones. 
# For each (phoneme) label in $SYMBOL_LIST,
#	set the initial HMM as the prototype hmm.
setenv SYMBOL_LIST lm/monophones0
rmtouch log/hcompv.log
scripts_sh_pl_py/hcompv.sh >> log/hcompv.log
exit

HEREST:		#	Step 6 of HTK tutorial on Chapter 3
# Now, re-estimate parameters of HMM models using embedded re-estimation.
# Meaning of arguments: the initial iteration no. is 1;
# 3 iterations are to be performed.
setenv SYMBOL_LIST lm/monophones0
rmtouch log/herest.log
scripts_sh_pl_py/herest.sh 1 3 >> log/herest.log

#	Step 7 of HTK tutorial on Chapter 3
# Add transitions from state 2 to state 4 and vice versa in silence model
# Add transition  from state 1 to state 3 of  short pause model.
# Tie the state 2 of sp model to center state of silence model. 
# The resultant models are stored in hmm/hmm5 directory.
setenv SYMBOL_LIST lm/monophones1
$HTK_HOME/scripts_sh_pl_py/hhedSil.sh >> log/herest.log

# herest.sh is again called to perform 2 re-estimation cycles 
# begining  with iteration no. 6
$HTK_HOME/scripts_sh_pl_py/herest.sh 6 2 >> log/herest.log
exit

ALIGN:	#	Step 8 of HTK tutorial on Chapter 3
# hviteAlign.sh realigns the training data using HMMs created so far 
#and it creates new transcriptions (with best pronunciation [out of many alternatives] for each recognised word) for aligned/training data.
  echo "sil []	sil" >> $FINAL_DICT
  rmtouch log/hviteAlign.log
  $HTK_HOME/scripts_sh_pl_py/hviteAlign.sh >> log/hviteAlign.log
# herest.sh is again called to perform 2 re-estimation cycles 
#begining  with iteration no. 8
  $HTK_HOME/scripts_sh_pl_py/herest.sh 8 2 >> log/herest.log
date
exit

HVITE_MONO:
# Recognise all data under wav directory  (test === TRAINING data).
# Compute MFCC features with delta and delta-delta
setenv CONFIG		htk_files/configs_test_hcopyMFCC12_D_A_0_Z
setenv TEST_HCOPY_SCP	htk_files/test_hcopy_script.txt
setenv TEST_SCP		htk_files/test_script.txt
rmtouch $TEST_HCOPY_SCP
find data/test/ -name '*.wav' |  \
  perl -ne 'chomp; $_ =~ /(.+)\.wav/;print "$_ $1.mfc_D_A\n"' >>$TEST_HCOPY_SCP
scripts_sh_pl_py/hcopy_MFCC12_D_A_0_Z.sh
rmtouch $TEST_SCP
perl -nae 'print "@F[1]\n"' htk_files/test_hcopy_script.txt >> $TEST_SCP

# Recognise using monophone HMMs and compute accuracy
setenv HMMDEFS		hmm/hmm9/hmmdefs
setenv MACROS		hmm/hmm9/macros
setenv RECOUT_MLF	log/recout_mono.mlf
setenv REF_WORD_MLF lm/${TASK}Word.mlf
rmtouch log/hvite_test.txt
scripts_sh_pl_py/hvite.sh >> log/hvite_test.txt
# Display performance figures
grep '\[H=' log/hvite_test.txt 
date
exit


DEMO:
setenv HMMDEFS hmm/hmm9/hmmdefs
setenv MACROS  hmm/hmm9/macros
setenv FINAL_DICT lm/sorted.lexicon.txt
#HParse lm/gram_number.txt lm/wdnet_number.txt
scripts_sh_pl_py/realLiveDemo.sh
exit


KWS:
setenv HMMDEFS hmm/hmm9/hmmdefs
setenv MACROS  hmm/hmm9/macros
setenv FINAL_DICT lm/lexicon_kws.txt
HParse lm/gram_kws.txt lm/wdnet_kws.txt
scripts_sh_pl_py/demo_kws.sh
exit

 

