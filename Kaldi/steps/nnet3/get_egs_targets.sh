#!/bin/bash

# Copyright 2012-2015 Johns Hopkins University (Author: Daniel Povey).
#           2015-2016 Vimal Manohar
# Apache 2.0.

# This script is similar to steps/nnet3/get_egs.sh but used
# when getting general targets (not from alignment directory) for raw nnet
#
# This script, which will generally be called from other neural-net training
# scripts, extracts the training examples used to train the neural net (and also
# the validation examples used for diagnostics), and puts them in separate archives.
#
# This script dumps egs with several frames of labels, controlled by the
# frames_per_eg config variable (default: 8).  This takes many times less disk
# space because typically we have 4 to 7 frames of context on the left and
# right, and this ends up getting shared.  This is at the expense of slightly
# higher disk I/O while training.


# Begin configuration section.
cmd=run.pl
feat_type=raw       # set it to 'lda' to use LDA features.
target_type=sparse  # dense to have dense targets,
                    # sparse to have posteriors targets
num_targets=        # required for target-type=sparse with raw nnet
frames_per_eg=8   # number of frames of labels per example.  more->less disk space and
                  # less time preparing egs, but more I/O during training.
                  # Note: may in general be a comma-separated string of alternative
                  # durations (more useful when using large chunks, e.g. for BLSTMs);
                  # the first one (the principal num-frames) is preferred.
left_context=4    # amount of left-context per eg (i.e. extra frames of input features
                  # not present in the output supervision).
right_context=4   # amount of right-context per eg.
left_context_initial=-1    # if >=0, left-context for first chunk of an utterance
right_context_final=-1     # if >=0, right-context for last chunk of an utterance
compress=true   # set this to false to disable compression (e.g. if you want to see whether
                # results are affected).
num_utts_subset=300     # number of utterances in validation and training
                        # subsets used for shrinkage and diagnostics.
num_valid_frames_combine=0 # #valid frames for combination weights at the very end.
num_train_frames_combine=60000 # # train frames for the above.
num_frames_diagnostic=10000 # number of frames for "compute_prob" jobs
samples_per_iter=400000 # this is the target number of egs in each archive of egs
                        # (prior to merging egs).  We probably should have called
                        # it egs_per_iter. This is just a guideline; it will pick
                        # a number that divides the number of samples in the
                        # entire data.

transform_dir=

stage=0
nj=6         # This should be set to the maximum number of jobs you are
             # comfortable to run in parallel; you can increase it if your disk
             # speed is greater and you have more machines.
srand=0
online_ivector_dir=  # can be used if we are including speaker information as iVectors.
cmvn_opts=  # can be used for specifying CMVN options, if feature type is not lda (if lda,
            # it doesn't make sense to use different options than were used as input to the
            # LDA transform).  This is used to turn off CMVN in the online-nnet experiments.

echo "$0 $@"  # Print the command line for logging

if [ -f path.sh ]; then . ./path.sh; fi
. parse_options.sh || exit 1;

if [ $# != 3 ]; then
  echo "Usage: $0 [opts] <data> <targets-scp> <egs-dir>"
  echo " e.g.: $0 data/train data/train/snr_targets.scp exp/tri4_nnet/egs"
  echo ""
  echo "Main options (for others, see top of script file)"
  echo "  --config <config-file>                           # config file containing options"
  echo "  --nj <nj>                                        # The maximum number of jobs you want to run in"
  echo "                                                   # parallel (increase this only if you have good disk and"
  echo "                                                   # network speed).  default=6"
  echo "  --cmd (utils/run.pl;utils/queue.pl <queue opts>) # how to run jobs."
  echo "  --samples-per-iter <#samples;400000>             # Target number of egs per archive (option is badly named)"
  echo "  --feat-type <lda|raw>                            # (raw is the default).  The feature type you want"
  echo "                                                   # to use as input to the neural net."
  echo "  --frames-per-eg <frames;8>                       # number of frames per eg on disk"
  echo "                                                   # May be either a single number or a comma-separated list"
  echo "                                                   # of alternatives (useful when training LSTMs, where the"
  echo "                                                   # frames-per-eg is the chunk size, to get variety of chunk"
  echo "                                                   # sizes).  The first in the list is preferred and is used"
  echo "                                                   # when working out the number of archives etc."
  echo "  --left-context <int;4>                           # Number of frames on left side to append for feature input"
  echo "  --right-context <int;4>                          # Number of frames on right side to append for feature input"
  echo "  --left-context-initial <int;-1>                  # If >= 0, left-context for first chunk of an utterance"
  echo "  --right-context-final <int;-1>                   # If >= 0, right-context for last chunk of an utterance"
  echo "  --num-frames-diagnostic <#frames;4000>           # Number of frames used in computing (train,valid) diagnostics"
  echo "  --num-valid-frames-combine <#frames;10000>       # Number of frames used in getting combination weights at the"
  echo "                                                   # very end."
  echo "  --stage <stage|0>                                # Used to run a partially-completed training process from somewhere in"
  echo "                                                   # the middle."

  exit 1;
fi

data=$1
targets_scp=$2
dir=$3

# Check some files.
[ ! -z "$online_ivector_dir" ] && \
  extra_files="$online_ivector_dir/ivector_online.scp $online_ivector_dir/ivector_period"

for f in $data/feats.scp $targets_scp $extra_files; do
  [ ! -f $f ] && echo "$0: no such file $f" && exit 1;
done

sdata=$data/split$nj
utils/split_data.sh $data $nj

mkdir -p $dir/log $dir/info


# Get list of validation utterances.
awk '{print $1}' $data/utt2spk | utils/shuffle_list.pl | head -$num_utts_subset | sort \
    > $dir/valid_uttlist || exit 1;

if [ -f $data/utt2uniq ]; then  # this matters if you use data augmentation.
  echo "File $data/utt2uniq exists, so augmenting valid_uttlist to"
  echo "include all perturbed versions of the same 'real' utterances."
  mv $dir/valid_uttlist $dir/valid_uttlist.tmp
  utils/utt2spk_to_spk2utt.pl $data/utt2uniq > $dir/uniq2utt
  cat $dir/valid_uttlist.tmp | utils/apply_map.pl $data/utt2uniq | \
    sort | uniq | utils/apply_map.pl $dir/uniq2utt | \
    awk '{for(n=1;n<=NF;n++) print $n;}' | sort  > $dir/valid_uttlist
  rm $dir/uniq2utt $dir/valid_uttlist.tmp
fi

awk '{print $1}' $data/utt2spk | utils/filter_scp.pl --exclude $dir/valid_uttlist | \
   utils/shuffle_list.pl | head -$num_utts_subset | sort > $dir/train_subset_uttlist || exit 1;

if [ ! -z "$transform_dir" ] && [ -f $transform_dir/trans.1 ] && [ $feat_type != "raw" ]; then
  echo "$0: using transforms from $transform_dir"
  if [ $stage -le 0 ]; then
    $cmd $dir/log/copy_transforms.log \
      copy-feats "ark:cat $transform_dir/trans.* |" "ark,scp:$dir/trans.ark,$dir/trans.scp"
  fi
fi
if [ -f $transform_dir/raw_trans.1 ] && [ $feat_type == "raw" ]; then
  echo "$0: using raw transforms from $transform_dir"
  if [ $stage -le 0 ]; then
    $cmd $dir/log/copy_transforms.log \
      copy-feats "ark:cat $transform_dir/raw_trans.* |" "ark,scp:$dir/trans.ark,$dir/trans.scp"
  fi
fi



## Set up features.
echo "$0: feature type is $feat_type"

case $feat_type in
  raw) feats="ark,s,cs:utils/filter_scp.pl --exclude $dir/valid_uttlist $sdata/JOB/feats.scp | apply-cmvn $cmvn_opts --utt2spk=ark:$sdata/JOB/utt2spk scp:$sdata/JOB/cmvn.scp scp:- ark:- |"
    valid_feats="ark,s,cs:utils/filter_scp.pl $dir/valid_uttlist $data/feats.scp | apply-cmvn $cmvn_opts --utt2spk=ark:$data/utt2spk scp:$data/cmvn.scp scp:- ark:- |"
    train_subset_feats="ark,s,cs:utils/filter_scp.pl $dir/train_subset_uttlist $data/feats.scp | apply-cmvn $cmvn_opts --utt2spk=ark:$data/utt2spk scp:$data/cmvn.scp scp:- ark:- |"
    echo $cmvn_opts >$dir/cmvn_opts # caution: the top-level nnet training script should copy this to its own dir now.
   ;;
  lda)
    splice_opts=`cat $transform_dir/splice_opts 2>/dev/null`
    # caution: the top-level nnet training script should copy these to its own dir now.
    cp $transform_dir/{splice_opts,cmvn_opts,final.mat} $dir || exit 1;
    [ ! -z "$cmvn_opts" ] && \
       echo "You cannot supply --cmvn-opts option if feature type is LDA." && exit 1;
    cmvn_opts=$(cat $dir/cmvn_opts)
    feats="ark,s,cs:utils/filter_scp.pl --exclude $dir/valid_uttlist $sdata/JOB/feats.scp | apply-cmvn $cmvn_opts --utt2spk=ark:$sdata/JOB/utt2spk scp:$sdata/JOB/cmvn.scp scp:- ark:- | splice-feats $splice_opts ark:- ark:- | transform-feats $dir/final.mat ark:- ark:- |"
    valid_feats="ark,s,cs:utils/filter_scp.pl $dir/valid_uttlist $data/feats.scp | apply-cmvn $cmvn_opts --utt2spk=ark:$data/utt2spk scp:$data/cmvn.scp scp:- ark:- | splice-feats $splice_opts ark:- ark:- | transform-feats $dir/final.mat ark:- ark:- |"
    train_subset_feats="ark,s,cs:utils/filter_scp.pl $dir/train_subset_uttlist $data/feats.scp | apply-cmvn $cmvn_opts --utt2spk=ark:$data/utt2spk scp:$data/cmvn.scp scp:- ark:- | splice-feats $splice_opts ark:- ark:- | transform-feats $dir/final.mat ark:- ark:- |"
    ;;
  *) echo "$0: invalid feature type --feat-type '$feat_type'" && exit 1;
esac

if [ -f $dir/trans.scp ]; then
  feats="$feats transform-feats --utt2spk=ark:$sdata/JOB/utt2spk scp:$dir/trans.scp ark:- ark:- |"
  valid_feats="$valid_feats transform-feats --utt2spk=ark:$data/utt2spk scp:$dir/trans.scp ark:- ark:- |"
  train_subset_feats="$train_subset_feats transform-feats --utt2spk=ark:$data/utt2spk scp:$dir/trans.scp ark:- ark:- |"
fi

if [ ! -z "$online_ivector_dir" ]; then
  steps/nnet2/get_ivector_id.sh $online_ivector_dir > $dir/info/final.ie.id || exit 1
  ivector_dim=$(feat-to-dim scp:$online_ivector_dir/ivector_online.scp -) || exit 1
  echo $ivector_dim > $dir/info/ivector_dim
  ivector_period=$(cat $online_ivector_dir/ivector_period) || exit 1;
  ivector_opts="--online-ivectors=scp:$online_ivector_dir/ivector_online.scp --online-ivector-period=$ivector_period"
else
  ivector_opts=""
  echo 0 >$dir/info/ivector_dim
fi

if [ $stage -le 1 ]; then
  echo "$0: working out number of frames of training data"
  num_frames=$(steps/nnet2/get_num_frames.sh $data)
  echo $num_frames > $dir/info/num_frames
  echo "$0: working out feature dim"
  feats_one="$(echo $feats | sed s:JOB:1:g)"
  if feat_dim=$(feat-to-dim "$feats_one" - 2>/dev/null); then
    echo $feat_dim > $dir/info/feat_dim
  else # run without stderr redirection to show the error.
    feat-to-dim "$feats_one" -; exit 1
  fi
else
  num_frames=$(cat $dir/info/num_frames) || exit 1;
  feat_dim=$(cat $dir/info/feat_dim) || exit 1;
fi


# the first field in frames_per_eg (which is a comma-separated list of numbers)
# is the 'principal' frames-per-eg, and for purposes of working out the number
# of archives we assume that this will be the average number of frames per eg.
frames_per_eg_principal=$(echo $frames_per_eg | cut -d, -f1)

# the + 1 is to round up, not down... we assume it doesn't divide exactly.
num_archives=$[$num_frames/($frames_per_eg_principal*$samples_per_iter)+1]
if [ $num_archives -eq 1 ]; then
  echo "*** $0: warning: the --frames-per-eg is too large to generate one archive with"
  echo "*** as many as --samples-per-iter egs in it.  Consider reducing --frames-per-eg."
  sleep 4
fi

# We may have to first create a smaller number of larger archives, with number
# $num_archives_intermediate, if $num_archives is more than the maximum number
# of open filehandles that the system allows per process (ulimit -n).
max_open_filehandles=$(ulimit -n) || exit 1
num_archives_intermediate=$num_archives
archives_multiple=1
while [ $[$num_archives_intermediate+4] -gt $max_open_filehandles ]; do
  archives_multiple=$[$archives_multiple+1]
  num_archives_intermediate=$[$num_archives/$archives_multiple+1];
done
# now make sure num_archives is an exact multiple of archives_multiple.
num_archives=$[$archives_multiple*$num_archives_intermediate]

echo $num_archives >$dir/info/num_archives
echo $frames_per_eg >$dir/info/frames_per_eg
# Work out the number of egs per archive
egs_per_archive=$[$num_frames/($frames_per_eg_principal*$num_archives)]
! [ $egs_per_archive -le $samples_per_iter ] && \
  echo "$0: script error: egs_per_archive=$egs_per_archive not <= samples_per_iter=$samples_per_iter" \
  && exit 1;

echo $egs_per_archive > $dir/info/egs_per_archive

echo "$0: creating $num_archives archives, each with $egs_per_archive egs, with"
echo "$0:   $frames_per_eg labels per example, and (left,right) context = ($left_context,$right_context)"
if [ $left_context_initial -ge 0 ] || [ $right_context_final -ge 0 ]; then
  echo "$0:   ... and (left-context-initial,right-context-final) = ($left_context_initial,$right_context_final)"
fi



if [ -e $dir/storage ]; then
  # Make soft links to storage directories, if distributing this way..  See
  # utils/create_split_dir.pl.
  echo "$0: creating data links"
  utils/create_data_link.pl $(for x in $(seq $num_archives); do echo $dir/egs.$x.ark; done)
  for x in $(seq $num_archives_intermediate); do
    utils/create_data_link.pl $(for y in $(seq $nj); do echo $dir/egs_orig.$y.$x.ark; done)
  done
fi

egs_opts="--left-context=$left_context --right-context=$right_context --compress=$compress --num-frames=$frames_per_eg"
[ $left_context_initial -ge 0 ] && egs_opts="$egs_opts --left-context-initial=$left_context_initial"
[ $right_context_final -ge 0 ] && egs_opts="$egs_opts --right-context-final=$right_context_final"

echo $left_context > $dir/info/left_context
echo $right_context > $dir/info/right_context
echo $left_context_initial > $dir/info/left_context_initial
echo $right_context_final > $dir/info/right_context_final

for n in `seq $nj`; do
  utils/filter_scp.pl $sdata/$n/utt2spk $targets_scp > $dir/targets.$n.scp
done

targets_scp_split=$dir/targets.JOB.scp

if [ $target_type == "dense" ]; then
  num_targets=$(feat-to-dim "scp:$targets_scp" - 2>/dev/null) || exit 1
fi

if [ -z "$num_targets" ]; then
  echo "$0: num-targets is not set"
  exit 1
fi

case $target_type in
  "dense")
    get_egs_program="nnet3-get-egs-dense-targets --num-targets=$num_targets"

    targets="ark:utils/filter_scp.pl --exclude $dir/valid_uttlist $targets_scp_split | copy-feats scp:- ark:- |"
    valid_targets="ark:utils/filter_scp.pl $dir/valid_uttlist $targets_scp | copy-feats scp:- ark:- |"
    train_subset_targets="ark:utils/filter_scp.pl $dir/train_subset_uttlist $targets_scp | copy-feats scp:- ark:- |"
    ;;
  "sparse")
    get_egs_program="nnet3-get-egs --num-pdfs=$num_targets"
    targets="ark:utils/filter_scp.pl --exclude $dir/valid_uttlist $targets_scp_split | ali-to-post scp:- ark:- |"
    valid_targets="ark:utils/filter_scp.pl $dir/valid_uttlist $targets_scp | ali-to-post scp:- ark:- |"
    train_subset_targets="ark:utils/filter_scp.pl $dir/train_subset_uttlist $targets_scp | ali-to-post scp:- ark:- |"
    ;;
  default)
    echo "$0: Unknown --target-type $target_type. Choices are dense and sparse"
    exit 1
esac

if [ $stage -le 3 ]; then
  echo "$0: Getting validation and training subset examples."
  rm -f $dir/.error 2>/dev/null
  $cmd $dir/log/create_valid_subset.log \
    $get_egs_program \
    $ivector_opts $egs_opts "$valid_feats" \
    "$valid_targets" \
    "ark:$dir/valid_all.egs" || touch $dir/.error &
  $cmd $dir/log/create_train_subset.log \
    $get_egs_program \
    $ivector_opts $egs_opts "$train_subset_feats" \
    "$train_subset_targets" \
    "ark:$dir/train_subset_all.egs" || touch $dir/.error &
  wait;
  [ -f $dir/.error ] && echo "Error detected while creating train/valid egs" && exit 1
  echo "... Getting subsets of validation examples for diagnostics and combination."
  $cmd $dir/log/create_valid_subset_combine.log \
    nnet3-subset-egs --n=$[$num_valid_frames_combine/$frames_per_eg_principal] ark:$dir/valid_all.egs \
    ark:$dir/valid_combine.egs || touch $dir/.error &
  $cmd $dir/log/create_valid_subset_diagnostic.log \
    nnet3-subset-egs --n=$[$num_frames_diagnostic/$frames_per_eg_principal] ark:$dir/valid_all.egs \
    ark:$dir/valid_diagnostic.egs || touch $dir/.error &

  $cmd $dir/log/create_train_subset_combine.log \
    nnet3-subset-egs --n=$[$num_train_frames_combine/$frames_per_eg_principal] ark:$dir/train_subset_all.egs \
    ark:$dir/train_combine.egs || touch $dir/.error &
  $cmd $dir/log/create_train_subset_diagnostic.log \
    nnet3-subset-egs --n=$[$num_frames_diagnostic/$frames_per_eg_principal] ark:$dir/train_subset_all.egs \
    ark:$dir/train_diagnostic.egs || touch $dir/.error &
  wait
  sleep 5  # wait for file system to sync.
  cat $dir/valid_combine.egs $dir/train_combine.egs > $dir/combine.egs

  for f in $dir/{combine,train_diagnostic,valid_diagnostic}.egs; do
    [ ! -s $f ] && echo "No examples in file $f" && exit 1;
  done
  rm -f $dir/valid_all.egs $dir/train_subset_all.egs $dir/{train,valid}_combine.egs
fi

if [ $stage -le 4 ]; then
  # create egs_orig.*.*.ark; the first index goes to $nj,
  # the second to $num_archives_intermediate.

  egs_list=
  for n in $(seq $num_archives_intermediate); do
    egs_list="$egs_list ark:$dir/egs_orig.JOB.$n.ark"
  done
  echo "$0: Generating training examples on disk"
  # The examples will go round-robin to egs_list.
  $cmd JOB=1:$nj $dir/log/get_egs.JOB.log \
    $get_egs_program \
    $ivector_opts $egs_opts "$feats" "$targets" \
    ark:- \| \
    nnet3-copy-egs --random=true --srand=\$[JOB+$srand] ark:- $egs_list || exit 1;
fi

if [ $stage -le 5 ]; then
  echo "$0: recombining and shuffling order of archives on disk"
  # combine all the "egs_orig.*.JOB.scp" (over the $nj splits of the data) and
  # shuffle the order, writing to the egs.JOB.ark

  # the input is a concatenation over the input jobs.
  egs_list=
  for n in $(seq $nj); do
    egs_list="$egs_list $dir/egs_orig.$n.JOB.ark"
  done

  if [ $archives_multiple == 1 ]; then # normal case.
    $cmd --max-jobs-run $nj JOB=1:$num_archives_intermediate $dir/log/shuffle.JOB.log \
      nnet3-shuffle-egs --srand=\$[JOB+$srand] "ark:cat $egs_list|" ark:$dir/egs.JOB.ark  || exit 1;
  else
    # we need to shuffle the 'intermediate archives' and then split into the
    # final archives.  we create soft links to manage this splitting, because
    # otherwise managing the output names is quite difficult (and we don't want
    # to submit separate queue jobs for each intermediate archive, because then
    # the --max-jobs-run option is hard to enforce).
    output_archives="$(for y in $(seq $archives_multiple); do echo ark:$dir/egs.JOB.$y.ark; done)"
    for x in $(seq $num_archives_intermediate); do
      for y in $(seq $archives_multiple); do
        archive_index=$[($x-1)*$archives_multiple+$y]
        # egs.intermediate_archive.{1,2,...}.ark will point to egs.archive.ark
        ln -sf egs.$archive_index.ark $dir/egs.$x.$y.ark || exit 1
      done
    done
    $cmd --max-jobs-run $nj JOB=1:$num_archives_intermediate $dir/log/shuffle.JOB.log \
      nnet3-shuffle-egs --srand=\$[JOB+$srand] "ark:cat $egs_list|" ark:- \| \
      nnet3-copy-egs ark:- $output_archives || exit 1;
  fi

fi

if [ $stage -le 6 ]; then
  echo "$0: removing temporary archives"
  for x in $(seq $nj); do
    for y in $(seq $num_archives_intermediate); do
      file=$dir/egs_orig.$x.$y.ark
      [ -L $file ] && rm $(readlink -f $file)
      rm $file
    done
  done
  if [ $archives_multiple -gt 1 ]; then
    # there are some extra soft links that we should delete.
    for f in $dir/egs.*.*.ark; do rm $f; done
  fi
  echo "$0: removing temporary"
  # Ignore errors below because trans.* might not exist.
  rm -f $dir/trans.{ark,scp} $dir/targets.*.scp 2>/dev/null
fi

echo "$0: Finished preparing training examples"
