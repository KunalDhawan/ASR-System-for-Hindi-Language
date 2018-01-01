#!/bin/csh 
#-----------------------------------------------------------------------------
# NAME OF THE FILE 	: prototype hmm/hcompv.sh
# PURPOSE		: Shell script to demonstrate HTK (ver2.0) Tool HCompv
# INPUT ARGUMENTS	: A list of HMMs.
# OUTPUT ARGUMENTS	: None.
# IN and OUT ARGS	: None.
# IMPLICIT INPUT  VARIABLES: A list of HMMs, directory name 
#                           (containing label files), training 
#      		           data (mfc) files, prototype HMM, configuration file.
# IMPLICIT OUTPUT VARIABLES: A new version of HMM.
# IMPLICIT IN and OUT VARIABLES: None.
# CALLED FUNCTIONS	: HTK (V2.0) tool HCompV.
#-----------------------------------------------------------------------------
date
alias rmtouch		'if (-e \!*) rm \!*; touch \!*'

echo " HCompV computes global mean and covariance of a set of training data."
echo " It is used to initialise parameters of HMM such that all component"
echo " means and covariances are set equal to the global data mean and covariance.\n"

# Create script file for HCompV (contains a list of *.mfc files).
rmtouch htk_files/hcompv_script.txt
perl -nae 'print "$F[1]\n"' htk_files/hcopy_script.txt >> \
	htk_files/hcompv_script.txt

HCompV \
  -C htk_files/configs_MFCC12_D_A_0_Z  # the configuration file for training\
  -f 0.01                # create variance floor macros with values equal \
  -m 			 # to 0.01 times the global variance \
  -M hmm/hmm0            # store the output HMM macro model files in the \
  -S htk_files/hcompv_script.txt # directory hmm/hmm0 \
  -T 1 \
  htk_files/proto        # INput: template/proto HMM file

#Copy the proto HMM definition file for all phonemes
rmtouch hmm/hmm0/hmmdefs
foreach phonename (`cat $SYMBOL_LIST`)
  cat hmm/hmm0/proto | sed -e s=proto=$phonename=g -  >> hmm/hmm0/hmmdefs
end

#create the macros file
mv hmm/hmm0/hmmdefs hmm/hmm0/original.hmmdefs	
grep -v '~o' hmm/hmm0/original.hmmdefs | grep -v STRE | grep -v VECS > \
	hmm/hmm0/hmmdefs
rmtouch hmm/hmm0/macros
head -3 hmm/hmm0/original.hmmdefs >> hmm/hmm0/macros
cat hmm/hmm0/vFloors >> hmm/hmm0/macros
rm hmm/hmm0/vFloors

echo "------------------------- End of hcompv.sh --------------------------"

date
exit 0
