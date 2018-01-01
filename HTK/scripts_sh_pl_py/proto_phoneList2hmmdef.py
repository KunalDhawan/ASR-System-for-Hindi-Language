#!/usr/bin/python
# 	From prototype hmm, create a single hmmdefs file that contain hmms of
# ALL phones

# Usage:  scripts_sh_perl/proto2hmmdefs.py  htk_files/proto  lm/phoneList.txt

import sys

f = open( sys.argv[1], 'r' )
hmm = f.readlines()
f.close()

f = open( sys.argv[2], 'r' )
phones = f.readlines()
f.close()

for i in range(1):
    print hmm[i].strip()

for phone in phones:
    phone = phone.strip()
    print '~h "' + phone + '"'

    for i in range(2,len(hmm)):
        print hmm[i].strip()

# History:
# Aug 2017: Adopted from syed/hmmdef.py:
#	changed from range(3) to range(1):	1st line of proto is common

