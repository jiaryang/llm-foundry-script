#!/bin/bash

set -x
export MASTER_ADDR=$(scontrol show hostnames $SLURM_JOB_NODELIST | head -n 1)
export MASTER_PORT=23456
export LOGLEVEL=INFO
export MODEL="mpt-30b"

script_path=$(realpath $0)
curr_dir=$(dirname ${script_path})

_config_env=(SLURM_JOB_NUM_NODES SLURM_NODEID MASTER_ADDR MASTER_PORT)
mapfile -t _config_env < <(for v in "${_config_env[@]}"; do echo "--env=$v"; done)

# Build Docker image
# This helps set up the environment by installing DeepSpeed and the other dependencies.
podman build -f "${curr_dir}/Dockerfile.rocm" -t mosaicml/llm-foundry:rocm .

# If there exists an obsolete container, remove it.
if [ "$(podman ps -aq -f name=mosaicml-llm-foundry)" ]; then
	podman rm mosaicml-llm-foundry
fi

#podman run --env SLURM_JOB_NUM_NODES=${SLURM_JOB_NUM_NODES} \
#	--env SLURM_NODEID=${SLURM_NODEID} \
#	--env MASTER_ADDR=${MASTER_ADDR} \
#	--env MASTER_PORT=${MASTER_PORT} \
podman run ${_config_env[@]} --env=MODEL\
	-tid --privileged --network=host --shm-size=64GB \
	-it --ulimit core=-1 --cap-add=SYS_PTRACE \
	--device=/dev/kfd --device=/dev/dri --security-opt seccomp=unconfined --group-add video \
	-w /src \
	--name=mosaicml-llm-foundry mosaicml/llm-foundry:rocm

podman exec mosaicml-llm-foundry /src/llm-foundry/scripts/pretrain_mpt.sh
set +x
