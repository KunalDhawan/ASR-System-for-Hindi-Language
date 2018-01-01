#!/usr/bin/perl -w
# File is scripts_sh_pl_py/phoneMlf2symbolList.pl.
# This script reads a phone MLF and generates a symbol list file
# (monophones0) and also the symbol list file with "sp" (monophones1).

if (@ARGV != 2) {
    die "Usage:   mlf2symbolList.pl in_phoneMlf_file out_symbolListFile\n".
	"Example: mlf2symbolList.pl lm/kannadaPhone0.mlf lm/monophone0\n\n";
}
 
# read in command line arguments
($mlf, $symbolFile0) = @ARGV;

# open MLF file.
open (MLF,"<$mlf") || die ("Unable to open mlf $mlf file for reading");
open (TMP,">.symbol.tmp") || die ("Unable to open .symbol.tmp file");
while ($line = <MLF>) {
    next if ($line =~ /^[".#]/ );
    print TMP $line;
}
close(MLF);
close(TMP);

system("sort .symbol.tmp | uniq > $symbolFile0; rm .symbol.tmp");

exit

