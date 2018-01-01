#!/usr/bin/perl -w
#***************************************************************************
# PURPOSE     : To create HMM for "sp" starting from a copy of "sil" model
# INPUT       : hmm3/hmmdefs
# OUTPUT      : HMM for "sp"
#***************************************************************************

if($#ARGV < 1) {
    die "USAGE   : $0 in_HTK_hmm_file out_sp_file\n".
	"Example : $0 hmm/hmm3/hmmdefs hmm/hmm3/sp\n"
	}

($infile, $outfile) = @ARGV;
open(IN,"<$infile")   || die "Can't open $infile :$!";
open(OUT,">$outfile") || die "Can't open output file $outfile :$!";

while (<IN>) {
 last if ($_ =~ /sil/);
}
#  print "discovered sil\n";

  print OUT "~h \"sp\"\n";
  print OUT "<BEGINHMM>\n"; 
  print OUT "<NUMSTATES> 3\n";
  print OUT "<STATE> 2\n";
while (<IN>) {
 last if ($_ =~ /MEAN/)
} 
while (<IN>) {
 last if ($_ =~ /MEAN/)
}
print OUT;
while (<IN>) {
  print OUT $_;
  last if($_ =~ /GCONST/);
}

print OUT "<TRANSP> 3\n";
print OUT "0.0  1.0  0.0\n";
print OUT "0.0  0.9  0.1\n";
print OUT "0.0  0.0  0.0\n";
print OUT "<ENDHMM>\n";
close IN;
close OUT;

