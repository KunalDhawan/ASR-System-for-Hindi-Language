/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
PURPOSE		: Given a headerless file (Fs = 8000Hz), this program
   removes pauses, if any. A pause is a silence segment longer than 0.3sec.
   The default value of 0.3sec can be changed (optional 3rd argument).
PSEUDOCODE      :
  Read headerless  speech data file (16bits, 8000Hz)
  Compute frame energy
  An end of speech segment is detected when a sil of duration > MAX_PAUSE
  Write output file containing only speech segments
CAUTION         :  8000Hz, 
IMPLICIT VARIABLES: 
CALLED FUNCTIONS: All function calls are preceeded by FUNCTION keyword.
AUTHOR		: Samudravijaya K
DATE WRITTEN	: 27-MAR-2007
LOG OF CHANGES	: Written after the source code
 * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
/*   %G%  %W%    sccs Id line */
#include <chief.h>		// ./inc/chief.h 
#include <endPoint.h>		// ./inc/endPoint.h   constant definition
#include <stdio.h>
#include <math.h>
#include <string.h>

FUNCTION int main(int argc, char *argv[])
{
  int	i,j,k;		/* loop indicies */
  FILE	*in_fp, *out_fp;	// in and out file pointers

  // variables related to speech data
  short s[MAX_SPEECH_SEC * SF]; // speech data array
  int	nsample;	// number of speech samples actually read
  int 	nframe;		// no. of frames =  nsample / frameSize
  float	energy[FRAME_RATE * MAX_SPEECH_SEC]; // frame energy (dB) array
  int	beginFrame, endFrame; // frame indicies: begin and end of speech

  // variables related to end point detection filter and logic
  float	filterOut[FRAME_RATE * MAX_SPEECH_SEC]; // end point detection filter
  int   nseg, iseg;	// no. of speech segments in this utterance
  int	minSpeech;	// min. no. of frames in a speech segment
  int	length;		// no. of frames in the longest dur seg
  int	first[MAX_SPEECH_SEG], last[MAX_SPEECH_SEG]; // frame indicies of 
                        // begin and end of speech segments

  // check the arguments
  if (argc < 3) {
    printf ("Usage  : %s in_rawSpeechFile out_rawSpeechFile [minSpeechFrame]\n", argv[0]);
    printf ("Example: %s test.raw out.raw\n", argv[0]);
    return 1;
  }
  minSpeech = (argc > 3) ? atoi(argv[3]) : MIN_SPEECH_SEG_FRAME;
  debug_g   = (argc > 4) ? atoi(argv[4]) : 0;

  /* Read headerless speech data file */
  nsample = -MAX_SPEECH_SEC * SF; 	// read atmost -(*nsample) data points
  if ((FUNCTION readSpeechData(argv[1], 0, &nsample, s)) LT 0) {
     return -1;
  }

  //Compute frame energy
  if ((FUNCTION computeLogEnergyShortArray20dBSNR(s, nsample, (int)FRAME_SIZE, 
					&nframe, energy)) LT 0) {
    return -1;
  }

  // Convolve with filter [IEEE Trans SAP 10(3)146-157(2002)  by Qi Li et al]
  // The above filter is `faulty'; used sin(x)
  if ((FUNCTION endPointDetectFilter(energy, nframe, filterOut)) LT 0) {
     return -1;
  }

  /* Use (sil/speech) state transition diagram to determine end points */
  if ((FUNCTION endPointArrayDetectLogic(nframe, filterOut, energy, minSpeech,
				    &nseg, first, last)) LT 0) {
    fprintf(stderr, "%s: no speechSeg detected in %s\n", argv[0], argv[1]);
    return -1;
  }

  /* Write speech data sans silence to outfile */
  if ( (out_fp = fopen(argv[2],"w")) == NULL)    {
     (void) printf("%s: Can't open output file %s\n", argv[0], argv[2]);
     return -1;
  }
  for (iseg=0; iseg < nseg; iseg++) {    
    beginFrame = first[iseg] - BEGIN_SIL_FRAME;
    if (beginFrame < 0) {   beginFrame = 0;}
    if ((iseg) AND (beginFrame < last[iseg-1] + END_SIL_FRAME)) {
      beginFrame = last[iseg-1] + END_SIL_FRAME + 1;
    }
    endFrame   = last[iseg] + END_SIL_FRAME;
    if (endFrame > nframe-1) {  endFrame = nframe-1; }

    i = beginFrame * (FRAME_SIZE);
    nsample = (endFrame - beginFrame + 1) * (FRAME_SIZE) * 2;
    fwrite(s+i, nsample, 1, out_fp); // write n samples to out file
  }
  fclose(out_fp);

  return 0;
}

/** LOG OF CHANGES	:
16-APR-07	chief
    if ((iseg) AND (endFrame > last[iseg-1] + END_SIL_FRAME)) {
      endFrame = last[iseg-1] + END_SIL_FRAME;
    }
   -->
    if ((iseg) AND (beginFrame < last[iseg-1] + END_SIL_FRAME)) {
      beginFrame = last[iseg-1] + END_SIL_FRAME + 1;
    }
*/

/* Local Variables: */
/* compile-command:"cc -c -I inc RemovePauses_raw8000.c "*/
/* End: */
