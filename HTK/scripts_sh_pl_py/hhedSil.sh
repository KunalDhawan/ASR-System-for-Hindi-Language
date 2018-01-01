#!/bin/csh
#-----------------------------------------------------------------------------
# NAME OF THE FILE 	: hhedSil.sh
# PURPOSE		: Shell script to demonstrate HTK (ver2.2) Tool HHEd
#			  for fixing silence model
# INPUT ARGUMENTS	: None.
# OUTPUT ARGUMENTS	: None.
# IN and OUT ARGS	: None.
# IMPLICIT INPUT  VARIABLES: a file containing a list of hmm models,
#			  MMF containing hmm definitions,
#			  edit command file for editing "sil" hmm model
# IMPLICIT OUTPUT VARIABLES: New hmm definition file in the specified directory
# IMPLICIT IN and OUT VARIABLES:
# CALLED FUNCTIONS	: HTK (V2.2) tool HHEd
#-----------------------------------------------------------------------------

echo ""
echo "******* Demonstration of HTK Tool HHEd for fixing silence model*********"
echo " This program demonstrates the use of the HTK tool HHEd to add extra "
echo " transitions in the silence & short pause model and to tie emitting  "
echo " state of short pause model to center state of silence model."
echo ""

if (! -e $SYMBOL_LIST) then
  echo " Sorry! $SYMBOL_LIST does not exist."
  echo " Program aborted."
  exit 1
endif

# check whether the edit command file exists or not
if (! -e htk_files/sil.hed) then
  echo " Sorry! htk_scripts/sil.hed does not exist! Program aborted! "
  exit 1
endif
cp hmm/hmm3/hmmdefs hmm/hmm4/hmmdefs
cp hmm/hmm3/macros  hmm/hmm4/macros
scripts_sh_pl_py/create_sp_model.pl hmm/hmm3/hmmdefs hmm/hmm3/sp
cat hmm/hmm3/sp >> hmm/hmm4/hmmdefs

# Note the use of HHEd here	
HHEd	\
  -A \
  -H hmm/hmm4/macros	# INPUT: load hmm definition file hmm/hmm4/newMacros \
  -H hmm/hmm4/hmmdefs \
  -M hmm/hmm5		# store new hmm definition file in directory hmm/hmm5 \
  -T 1 		\
     htk_files/sil.hed # INPUT:edit command file for editing "sil" hmm model \
     $SYMBOL_LIST	# a file containing a list of hmm models


echo ""
echo " New hmm definition file created in directory hmm/hmm5 "
echo "------------------------- End of hhedSil.sh ---------------------------"



    


