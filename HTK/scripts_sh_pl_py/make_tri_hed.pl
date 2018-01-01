#!/usr/bin/perl
#
# make a .hed script to clone monophones in a phone list 
# 
# rachel morton 6.12.96
# https://github.com/ibillxia/htk_3_4_1/blob/master/samples/HTKTutorial/maketrihed

if (@ARGV != 2) {
  print "usage: make_tri_hed.pl monophoneList triphoneList\n\n"; 
  exit (0);
}

($monolist, $trilist) = @ARGV;		# Two INPUTs

# open .hed script
open(MONO, "@ARGV[0]");


# open .hed script
open(HED, ">mktri.hed");		# one OUTPUT

print HED "CL $trilist\n";

# 
while ($phone = <MONO>) {
       chop($phone);
       if ($phone ne "") { 
	   print HED "TI T_$phone {(*-$phone+*,$phone+*,*-$phone).transP}\n";
       }
   }

