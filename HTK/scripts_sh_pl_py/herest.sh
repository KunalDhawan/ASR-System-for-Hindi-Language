#!/bin/csh 
#-----------------------------------------------------------------------------
# NAME OF THE FILE 	: herest.sh
# PURPOSE		: Shell script to demonstrate HTK (ver2.0) Tool HERest
# INPUT ARGUMENTS	: Initial iteration no., no. of iterations.
# OUTPUT ARGUMENTS	: none
# IN and OUT ARGS	: none
# IMPLICIT INPUT  VARIABLES: Configuration file (feature extraction),
#			  script file containing a list of training files,
#			  MLF file containing the corresponding *.lab files.
#			  list of hmm models to be re-estimated.
# IMPLICIT OUTPUT VARIABLES: new macros file in the directory hmm[1-*]
# IMPLICIT IN and OUT VARIABLES: none.
# CALLED FUNCTIONS	: HTK (v2.0) tool HERest
#-----------------------------------------------------------------------------

if ($2 == "") then
  echo " Usage	: herest.csh <initial_iteration_no> <no_of_iterations>"
  echo " Example: herest.csh 1 3 "
  echo " Please try again\!"
  exit 1
endif

# if the required files do not exist, then abort.
foreach ff ($CONFIG $SYMBOL_LIST $PHONE_MLF $FEATURE_SCRIPT)
    if (! -e $ff) then
	echo " Sorry\! $ff does not exist. "
	echo " Program aborted."
	exit 1
    endif
end

set curr_iter=$1
set no_of_iter=$2	
set max_iter = `expr $curr_iter + $no_of_iter - 1`
set prev_iter = 0

echo "phone list file is $SYMBOL_LIST"
while($curr_iter <= $max_iter)
  @ prev_iter = $curr_iter - 1
  echo " previous iteration = $prev_iter"
  echo " Iteration no : $curr_iter "
  echo " Source directory : hmm/hmm$prev_iter"
  echo " Destination directory : hmm/hmm$curr_iter"
  
  # Note the use of HERest below 
  HERest	\
    -A \
    -C $CONFIG		            # INPUT:config file used for deriving \
    		                    # features from wave files (using hcopy).\
    -H hmm/hmm$prev_iter/macros # INPUT: macros/hmms generated previously \
    -H hmm/hmm$prev_iter/hmmdefs \
    -I $PHONE_MLF                    \
    -M hmm/hmm$curr_iter	# new hmm models to be written in this dir.\
    -S $FEATURE_SCRIPT		# INPUT: contains a list of feature files. \
    -T 1			# basic tracing level \
    -t 250.0 150.0 1000.0	# {pruning, delta, max}threshold for alpha/B \
    -s hmm/hmm$curr_iter/stats.txt # OUTPUT:Generate state occupation statistics.\
       $SYMBOL_LIST	        # INPUT: List of HMM models
  @ curr_iter++
end
echo "--------------------------- End of herest.sh  ------------------------ "



