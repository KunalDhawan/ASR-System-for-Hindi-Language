#!/bin/csh
# NAME OF THE FILE 	: machinename::path
# PURPOSE		: To write transcriptions for *.wav files (in current
#                         directory) corresponding to sentences with serial numbers
# INPUT ARGUMENTS	: None                    
# OUTPUT ARGUMENTS	:
# IMPLICIT INPUT  VARIABLES     : doc/digitSequences80.txt
# IMPLICIT OUTPUT VARIABLES     : *.trans files in same directory as *.wav
#----------------------------------------------------------------------------


foreach ff (`ls data/train/*/*.wav`)
  set transFile = `echo $ff | sed s=wav=trans= -`
  set id = `echo $ff | perl -ne '$_ =~ /$ENV{LANGUAGE}.*(\d\d\d)\.wav$/; print $1'` 
  set line = `grep $id doc/hindiSentences150.txt`  
  echo $line | perl -ne '$_ =~ /^\d\d\d\) (.+)$/; print "$1\n"' > $transFile
end

foreach ff (`ls data/test/*/*.wav`)
  set transFile = `echo $ff | sed s=wav=trans= -`
  set id = `echo $ff | perl -ne '$_ =~ /$ENV{LANGUAGE}.*(\d\d\d)\.wav$/; print $1'` 
  set line = `grep $id doc/hindiSentences150.txt`  
  echo $line | perl -ne '$_ =~ /^\d\d\d\) (.+)$/; print "$1\n"' > $transFile
end





# REVISION HISTORY	: 05-OCT-2017
