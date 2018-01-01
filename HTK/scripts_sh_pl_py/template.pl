#!/usr/bin/perl -w
#***************************************************************************
# PURPOSE     : To extract 10 digit models from HTK hmm file
# INPUT       : HTK hmm file.
# OUTPUT      : HTK hmm file (containing only digit models)
# AUTHOR      : chief
#***************************************************************************

if($#ARGV < 1) {
    die "USAGE   : $0 in_HTK_hmm_file out_HmmFile\n".
	"Example : $0 hmmdefs hmmdefs.digits\n"
	}

($infile, $outfile) = @ARGV;
open(IN,"<$infile")   || die "Can't open $infile :$!";
open(OUT,">$outfile") || die "Can't open output file $outfile :$!";

while ($line = <IN>) {
    if ($line =~ /^~h \"(\w+)\"/) {
	# do something
    } else {
	print OUT $line;
    } # end: ($line =~ /^~h \"(\w+)\"/) {
} # End of while ($line = <IN>) {

close IN;
close OUT;
