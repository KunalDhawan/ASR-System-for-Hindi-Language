/** * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
 ** PURPOSE		: To detect the end-points of an utterance;
        Write, to an output file, the utterance with atmost "BEGIN_SILENCE"
	and "END_SILENCE" secs of silence at the beginning and end of  the
	utterance.
 CAUTION:
        0) Assumes that all frames less than meanLogE are silence frames!!!
        1) This is a VERY crude method; not meant for critical boundary
                 detection; Constants are to be tuned to SNR.
	2) Assumes that the data is in native byte order format.
	3) Sampling frequency = 16000 assumed.
 

 ** GLOBAL VARIABLES USED: errCode_g
 ** RETURN VALUES	:	0	success 
 **				-ve	Fatal error
 ** CALLED FUNCTIONS    : See prototype definitions below.
 ** AUTHOR		:Samudravijaya K 
 ** DATE WRITTEN	: Nov 15, 97    ,2008
 ** LOG OF CHANGES	: See the end of this file
 ** * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
#include <stdio.h>
#include <string.h>
#include <math.h>

/* Macros */

#define TRUE	1
#define FALSE	0
#define YES	1
#define NO	0

#define FUNCTION                /* place holder */
#define AND     &&
#define OR      ||
#define EQUAL   ==
#define EQ      ==
#define NE      !=
#define LT      <
#define LE      <=
#define GT      >
#define GE      >=
#define NOT     !

/* Called Functions */
FUNCTION int ReadSpeechData
(			/**  input: */
 char	*wavFname,		/* Name of file containing speech data */
 int	nskip,			/* No. of bytes to skip in the begining */
 int	*nsample,		/* No. of samples actually to be read
				 * if (*nsample < 0) ==> read atmost -(*nsample)
				 * data points. */
			/** output: */
 /* int	*nsample,		  No. of samples actually read */
 short	*speech			/* speech[0:*nsample-1] is returned	*/
);

/* Global variable */

int     errCode_g;

/* Constants */

#define SF         16000            /* sampling frequency */
#define FRAME_RATE 100
#define FRAME_SIZE SF/FRAME_RATE    /* size of analysis frame = 10 msec */
#define MAX_SPEECH_SEC 10           /* MAX 10 secs of speech data */
#define MAX_FRAMES FRAME_RATE * MAX_SPEECH_SEC
#define SIL_THRESHOLD_FACTOR 0.1
#define SIL_FRAME_FRACTION   0.1
#define BEGIN_SILENCE	0.1
#define END_SILENCE	0.1
#define DEBUG		0

/*********************************************************/
/* The function main program (RemoveEndSilence) begins here */
/*********************************************************/

 int main(
			/**  input: */
 int argc,                      /* No. of commandline arguments */
 char *argv[]                   /* the char array of arguments */
)

{
  int     i, j, k, n;		/* loop indicies */
  FILE  *in_fp, *out_fp, *lab_fp;

  char  wavFname[256], fname[256];
  short speech[SF*MAX_SPEECH_SEC];
  short zero[FRAME_SIZE];
  short	*s;			/* pointer to begin of frame */
  int	nskip = 0;

  int	nsample;		/* No. of sampled data */
  int	nfr;			/* No. of frames */
  int	frmsiz;			/* size of analysis frame */
  int	shift;			/* shift between successive frames */
  int	nsilFrame;		/* No. of silence frames */
  int	imin, imax;		/* min and max amplitude of "speech" frames */
  int	ampl[MAX_FRAMES];	/* pointer: max wavform envelope in frame */
  int   frameW[MAX_FRAMES];
  int	begin, end;		/* utterance end frames nos. */

  float sum, sumsqr;		/* Temporary variables for mean and SD calcn */
  float	mean, sd;		/* mean and standard deviation of log energy */
  float	temp, factor;		/* Temporary variables */

  if (argc LT 4)
  { fprintf(stderr, "\aUSAGE : %s inSpeechFile outSpeechFile nskip_bytes\n",
	    argv[0]);
    return (1);
  }

  /* Read speech data */
  strcpy(wavFname, argv[1]);
  sscanf(argv[3], "%d", &nskip);
  nsample = - SF*MAX_SPEECH_SEC;	/* read atmost SF*MAX.. data */
  FUNCTION ReadSpeechData(wavFname, nskip, &nsample, speech);
  if (nsample LE 0)
  { errCode_g = -1;
    return errCode_g;
  }

  /* FUNCTION SwapBytes(nsample, speech); */


  frmsiz = FRAME_SIZE;
  shift  = frmsiz;                     /* non-overlapping analysis frames */
  nfr	= nsample/shift;               /* No. of analysis frames */

  /*************************************************************************
   * Set energy threshold as the mean of maximum positive amplitude
   * (a simple measure of frame energy) in frame.
   *************************************************************************/

  s	= speech;			/* s is a pointer to begin of frame */
  sum=0.0; sumsqr=0.0;
  for (k=0; k < nfr; k++) {
    short a=0;				/* max +ve wavform envelope */
    for (i=0; i < frmsiz; i++) {
      if (s[i] GT a) a=s[i];		/* Negative excursions ignored */
    }
    sum	+= a;		       	/*  for the sake of simplicity */
    sumsqr	+= (float)a * (float)a;
    ampl[k]	= a;
    s	+= shift;
  }
  mean	= sum / (float)nfr;
  if (DEBUG) { printf("\nmean = %.1f\n", mean, sd); }

  /* Mark "silence" frames. */
  for (k=0; k <nfr ; k++) {
    frameW[k] = (ampl[k] GT mean) ? 1 : 0;
  }	

  /******************************************************************
   * Run the frame weight array thru a 5-point median smooth filter
   * to ignore short speech segment or short silence segment.
   ******************************************************************/

  for (k=2; k LT nfr-2; k++)
  { int isum;
    isum = frameW[k-2] + frameW[k-1] + frameW[k] + frameW[k+1] + frameW[k+2];
    frameW[k] = (isum > 2) ? 1 : 0;
  }

  /* Determine the end-points of the utterance */
  for (k=0; k LT nfr; k++)
  { if (frameW[k] NE 0)
      break;
  }
  begin = k-FRAME_RATE*BEGIN_SILENCE;
  for (k=nfr-1; k GT begin; k--)
  { if (frameW[k] NE 0)
      break;
  }
  end = k+FRAME_RATE*END_SILENCE;
  if (DEBUG) { printf("begin = %d;\t end = %d\n", begin, end); }
  if (begin LT 0) begin = 0;
  if (end GE nfr) end = nfr-1;
  nsample = shift * (end-begin+1);
  /* FUNCTION SwapBytes(nsample, &(speech[shift*begin])); */

  /* Write the speech data excluding end-silence of length more than
   * BEGIN_SILENCE and END_SILENCE secs. */
  if((out_fp = fopen(argv[2],"w")) EQ NULL)
  { fprintf(stderr,"Error in opening file for writing: %s\n", argv[2]);
    return(-3);
  }
  fwrite(&(speech[shift*begin]), 2, nsample, out_fp);
  fclose (out_fp);

  return 0;
}				/* end of function RemoveSilence */

/*************************************************************/

/***************************************/ 
/* Function ReadSpeechData begins here */
/***************************************/

FUNCTION int ReadSpeechData
(			/**  input: */
 char	*wavFname,		/* Name of file containing speech data */
 int	nskip,			/* No. of bytes to skip in the begining */
 int	*nsample,		/* No. of samples actually to be read
				 * if (*nsample < 0) ==> read atmost -(*nsample)
				 * data points. */
			/** output: */
 /* int	*nsample,		  No. of samples actually read */
 short	*speech			/* speech[0:*nsample-1] is returned	*/
)
{
  char *module	= "ReadSpeechData";
  FILE *in_fp = stdin;		/* input and output file pointers */
  int	n;
  int	readAll = FALSE;

  if((in_fp = fopen(wavFname,"rb")) EQ NULL)
  { fprintf(stderr,"Error in opening file for reading%s", wavFname);
    return(-1);
  }

  if (nskip GT 0)
  { fseek(in_fp, (long)nskip, SEEK_SET);
  }  
  if (*nsample LT 0)
  { *nsample = -(*nsample);
    readAll  = TRUE;
  }
  n = fread(speech, sizeof(short), *nsample, in_fp);
  fclose(in_fp);
  if ((n NE *nsample) AND (NOT readAll))
  { fprintf(stderr, "%s\t: Could read only \t%d ( < %d{desired}) samples"
	    "from \n\t%s\n", module, n, *nsample, wavFname);
    errCode_g = (n GT 0) ? 11 : -11;
  }
  *nsample = n;

  return errCode_g;
}				/* end of function ReadSpeechData */


/***************************************/ 
/* Function SwapBytes begins here */
/***************************************/

FUNCTION int SwapBytes
(			/**  input: */
 int	nsample,		/* No. of samples (2bytes) */
 char	*s		       	/* speech data */
			/** output: */
  /* char	s[nsample*2]	 byte swapped speech data */
)
{
  int	i;
  char temp;

  for (i=0; i < nsample*2; i+=2)
    {
      temp	= s[i];
      s[i]	= s[i+1];
      s[i+1]	= temp;
    }
}

/*----------------------------------------------------------------------*/

/**	LOG OF CHANGES:
  17-APR-2000	chief
        Read speech Data skips nskip bytes and not short elements.
	argv[3] is the nbytes to skip.
	The line	nsample = frmsiz * (end-begin+1);
	changed to	nsample = shift  * (end-begin+1);
  07-MAR-08
        Uses meanLogE as the threshold.
 */
/** Local Variables: */
/** compile-command:"cc -c RemoveEndSilence.c "*/
/** End: */
