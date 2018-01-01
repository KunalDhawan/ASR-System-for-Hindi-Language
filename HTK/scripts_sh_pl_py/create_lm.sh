#!/bin/csh
# NAME OF THE FILE 	: $HTK_HOME/scripts_sh_pl_py/create_lm.sh
# PURPOSE		: To generate a file containing transcriptions and 
#	Master Label Files at phone level and word level.
#	Bigram grammar files
#	lists of symbols (monophones0 and monophones1)
# IMPLICIT INPUT  VARIABLES     :
#	data/*/*.trans
#	$DICT	=== lm/lexicon.txt
# IMPLICIT OUTPUT VARIABLES     : 
#	$FINAL_DICT	=== lm/sorted.lexicon.txt
#	htk_files/transcriptions.txt 
#	lm/${TASK}Word.mlf 
#	lm/bglm
#----------------------------------------------------------------------------
date
# if the required files do not exist, then abort.
foreach ff ($DICT)
    if (! -e $ff) then
	echo " Sorry\! $ff does not exist. "
	echo " Program aborted."
	exit 1
    endif
end
alias rmtouch		'if (-e \!*) rm \!*; touch \!*'
foreach ff (htk_files/transcriptions.txt lm/${TASK}Word.mlf )
  rmtouch $ff 
end

# Create htk_files/transcriptions.txt and lm/${TASK}Word.mlf
echo "#\!MLF\!#" >> lm/${TASK}Word.mlf
foreach ff (`find data/train/ -name '*.trans' ` )
  cat $ff | perl -ne 'chomp; print "SENT_BEGIN $_ SENT_END\n"' \
	>> htk_files/transcriptions.txt
  echo $ff | perl -ne '$_ =~ /.*\/(.+).trans/; print "\"\*\/$1.lab\"\n"' \
	>> lm/${TASK}Word.mlf
  cat $ff | perl -nae 'foreach $w (@F) {print "$w\n"}; print ".\n"'  \
	>> lm/${TASK}Word.mlf
end

foreach ff (`find data/test/ -name '*.trans' ` )
  cat $ff | perl -ne 'chomp; print "SENT_BEGIN $_ SENT_END\n"' \
	>> htk_files/transcriptions.txt
  echo $ff | perl -ne '$_ =~ /.*\/(.+).trans/; print "\"\*\/$1.lab\"\n"' \
	>> lm/${TASK}Word.mlf
  cat $ff | perl -nae 'foreach $w (@F) {print "$w\n"}; print ".\n"'  \
	>> lm/${TASK}Word.mlf
end

# Generate Bigram grammar
LNewMap -f WFC ${TASK} lm/${TASK}.wmap
LGPrep -A -T 1 -a 10000 -b 200000 -d lm -n 4 \
	-s ${TASK} lm/${TASK}.wmap htk_files/transcriptions.txt 
LGCopy -A -T 1 -b 200000 -d lm lm/wmap lm/gram.*
LBuild -A -T 1 -f TEXT -c 2 1 -n 2 lm/wmap lm/bglm lm/data.*

rmtouch $FINAL_DICT
echo "SENT_BEGIN [] sil" >> $FINAL_DICT
echo "SENT_END [] sil" >> $FINAL_DICT
sort $DICT | uniq >> $FINAL_DICT
HBuild -s "SENT_BEGIN" "SENT_END" -n lm/bglm $FINAL_DICT lm/wordent_bigram
#HBuild -s SENT_BEGIN SENT_END -n lm/bglm $FINAL_DICT lm/wordent_bigram

# create the phone MLF and the symbol lists (monophones0, monophones1).
rmtouch htk_files/mkphones0.led
echo "EX" >> htk_files/mkphones0.led
echo "IS sil sil" >> htk_files/mkphones0.led
echo "DE sp" >> htk_files/mkphones0.led
HLEd -l '*' -d $FINAL_DICT -i lm/${TASK}Phone0.mlf \
	htk_files/mkphones0.led lm/${TASK}Word.mlf
scripts_sh_pl_py/phoneMlf2symbolList.pl lm/${TASK}Phone0.mlf lm/monophones0

rmtouch lm/monophones1
rmtouch junk.txt
echo "sp" >> junk.txt
cat lm/monophones0 junk.txt | sort >> lm/monophones1
rm junk.txt

date
exit 0

# REVISION HISTORY	: 05-OCT-2017
