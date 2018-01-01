#!/bin/bash
clear
#set-up for single machine or cluster based execution
. ./cmd.sh
#set the paths to binaries and other executables
[ -f path.sh ] && . ./path.sh
train_cmd=run.pl
decode_cmd=run.pl

feat_nj=10
train_nj=30
decode_nj=10
#================================================
#	SET SWITCHES
#================================================

mfcc_extract_sw=0

mono_train_sw=0
mono_test_sw=0

tri_train_sw=0
tri_test_sw=0

dnn_train_sw=1
dnn_test_sw=1

#================================================
#      Set Directories
#================================================

train_dir=data/train
test_dir=data/test

lang_dir=data/lang_bigram

graph_dir=graph
decode_dir=decode

exp=exp_FG

#====================================================

if [ $mfcc_extract_sw == 1 ]; then

echo ============================================================================
echo "         MFCC Feature Extration & CMVN for Training               "
echo ============================================================================
#extract MFCC features and perfrom CMVN

mfccdir=mfcc

for x in train test; do 
        utils/fix_data_dir.sh data/$x;
	steps/make_mfcc.sh --cmd "$train_cmd" --nj "$feat_nj" data/$x $exp/make_mfcc/$x $mfccdir || exit 1;
 	steps/compute_cmvn_stats.sh data/$x $exp/make_mfcc/$x $mfccdir || exit 1;
	utils/validate_data_dir.sh data/$x;
done
fi

if [ $mono_train_sw == 1 ]; then

echo ============================================================================
echo "                   MonoPhone Training                	        "
echo ============================================================================

steps/train_mono.sh  --nj "$train_nj" --cmd "$train_cmd" $train_dir $lang_dir $exp/mono || exit 1; 

fi

if [ $mono_test_sw == 1 ]; then

echo ============================================================================
echo "                   MonoPhone Testing             	        "
echo ============================================================================

utils/mkgraph.sh --mono $lang_dir $exp/mono $exp/mono/$graph_dir || exit 1;
steps/decode.sh --nj "$decode_nj" --cmd "$decode_cmd" $exp/mono/$graph_dir $test_dir $exp/mono/$decode_dir || exit 1;

fi

if [ $tri_train_sw == 1 ]; then

echo ============================================================================
echo "                      Tri-phone Training                    "
echo ============================================================================

steps/align_si.sh --boost-silence 1.25 --nj "$train_nj" --cmd "$train_cmd" $train_dir $lang_dir $exp/mono $exp/mono_ali || exit 1; 

for sen in 2000; do 
for gauss in 8; do 
gauss=$(($sen * $gauss)) 

echo "========================="
echo " Sen = $sen  Gauss = $gauss"
echo "========================="

steps/train_deltas.sh --cmd "$train_cmd" $sen $gauss $train_dir $lang_dir $exp/mono_ali $exp/tri_8_$sen || exit 1; 
done;done

fi

if [ $tri_test_sw == 1 ]; then

echo ============================================================================
echo "                  Tri-phone  Decoding                     "
echo ============================================================================

for sen in 2000; do  

echo "========================="
echo " Sen = $sen "
echo "========================="

utils/mkgraph.sh $lang_dir $exp/tri_8_$sen $exp/tri_8_$sen/$graph_dir || exit 1;
steps/decode.sh --nj "$decode_nj" --cmd "$decode_cmd"  $exp/tri_8_$sen/$graph_dir $test_dir $exp/tri_8_$sen/$decode_dir || exit 1;

done

fi


if [ $dnn_train_sw == 1 ]; then

echo ============================================================================
echo "                    DNN Hybrid Training                   "
echo ============================================================================

steps/align_si.sh --nj "$train_nj" --cmd "$train_cmd" $train_dir $lang_dir $exp/tri_8_2000 $exp/tri_8_2000_ali || exit 1;

# DNN hybrid system training parameters

 steps/nnet2/train_tanh.sh --mix-up 5000 --initial-learning-rate 0.015 \
 --final-learning-rate 0.002 --num-hidden-layers 3 --minibatch-size 128 --hidden-layer-dim 256 \
 --num-jobs-nnet "$train_nj" --cmd "$train_cmd" --num-epochs 15 \
  $train_dir $lang_dir $exp/tri_8_2000_ali $exp/DNN_tri_8_2000_aligned_layer3_nodes256

fi

if [ $dnn_test_sw == 1 ]; then

echo ============================================================================
echo "                    DNN Hybrid Testing                    "
echo ============================================================================

steps/nnet2/decode.sh --cmd "$decode_cmd" --nj "$decode_nj" \
 $exp/tri_8_2000/$graph_dir $test_dir \
  $exp/DNN_tri_8_2000_aligned_layer3_nodes256/$decode_dir | tee $exp/DNN_tri_8_2000_aligned_layer3_nodes256/$decode_dir/decode.log

fi
