#!/bin/csh
if ($#argv < 1) then
  echo "Usage  : $0 inDevnagFname  outSphinxFname"
  echo "Example: $0 hindi06.dn     hindi06.prompts"
  exit 1
endif

# REVISION HISTORY	:
