#!/bin/bash

set -x

export HIP_VISIBLE_DEVICES=0,1,2,3,4,5,6,7

script_path=$(realpath $0)
curr_dir=$(dirname ${script_path})

NUM_NODES=${SLURM_JOB_NUM_NODES:-1}
NODE_RANK=${SLURM_NODEID:-0}
NUM_GPUS=8
WORD_SIZE=$(($NUM_NODES*$NUM_GPUS))
MODEL=${MODEL:-mpt-1b}

#echo "NUM_NODES="${NUM_NODES}
#echo "NODE_RANK="${NODE_RANK}
#echo "WORD_SIZE="${WORD_SIZE}
#echo "MODEL="${MODEL}

run_cmd="composer"

if [ ${NUM_NODES} -gt 1 ]; then
	run_cmd+=" \
	--world_size ${WORD_SIZE} \
	--node_rank $NODE_RANK \
	--master_addr $MASTER_ADDR \
	--master_port $MASTER_PORT"
fi

#echo "==== pretrain_mpt.sh ===="
#echo ${run_cmd}
#echo "==== pretrain_mpt.sh ===="


run_cmd+=" \
	${curr_dir}/train/train.py \
	${curr_dir}/train/yamls/pretrain/${MODEL}.yaml \
	data_local=${curr_dir}/my-copy-c4 \
	train_loader.dataset.split=train_small \
	eval_loader.dataset.split=val_small \
	max_duration=15ba eval_interval=0 \
	model.loss_fn=torch_crossentropy model.attn_config.attn_impl=flash"

echo "${run_cmd}"
eval "${run_cmd}"

