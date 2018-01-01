#!/bin/csh
# NAME OF THE FILE 	: machinename::path
# PURPOSE		: To record a series of audio files corresponding to
#                         sentences with serial numbers
# INPUT ARGUMENTS	: startSentId
#                         spkrId                         
# OUTPUT ARGUMENTS	:
# IMPLICIT INPUT  VARIABLES     : langId
# IMPLICIT OUTPUT VARIABLES     : Wavefiles stored in wav_langId/ directory.
#----------------------------------------------------------------------------



set nsec   = 6;             # Duration of each speech file (no. of seconds)
set langId = AS             # Edit this line corresponding to your language

set dirName = "~/wav17_$langId"
if (! -e $dirName) mkdir $dirName
cd $dirName                 # change to appropriate directory.

echo -n "Enter a single letter (M or F) indicating the gender of the speaker:"
set input = $<
set gender = ` echo $input | tr "[a-z]" "[A-Z]" `
echo -n "Enter the speaker Id (Ex: 5): "
set input = $<
set spkrId = `printf "%03d\n" $input`
echo -n "Enter the serial number (Ex: 11) of the first sentence to be recorded in this recording session: "
set sentNum = $<
#set sentId = `printf "$d\n" $input`

echo "Type control c to terminate the recording session at any time"

set n = 0
while ($n < 50)              # Record upto 50 sentences in a recording session
  set sentId = `printf "%04d\n" $sentNum`
  set fname = "$langId""$spkrId""$gender""$sentId"".wav"
  echo " "
  echo -n "Press enter and read sentence (Number = $sentNum) within $nsec seconds: "
  set start = $<
  rec -V1 -r 16000 -b 16 -c 1 $fname trim 0 $nsec
  @ n++
  @ sentNum++
end
echo "Thanks; the recording session is over".

# REVISION HISTORY	:
