#!/bin/bash

set -x

partition_name=${1:-"1CN128C8G2H_2IB_MI210_Ubuntu22"}
num_nodes=${2:-1}
models=${3:-mpt-1b}

pattern='^[0-9]+$'
if ! [[ ${num_nodes} =~ ${pattern} ]]; then
	echo "Error: num_nodes (${num_nodes}) not a number"
	        exit
	elif [ ${num_nodes} -lt 1 ]; then
		echo "Error: num_nodes must be at least 1"
		exit
fi

script_path=$(realpath $0)
curr_dir=$(dirname ${script_path})
template_slurm="${curr_dir}/slurm_pretrain_gpt_TEMPLATE.sh"

if [ ${num_nodes} -eq 1 ]; then
	slurm_script="${curr_dir}/slurm_pretrain_gpt_single_node.sh"
else
	slurm_script="${curr_dir}/slurm_pretrain_gpt_${num_nodes}nodes.sh"
fi

sed "s/PARTITION_NAME/${partition_name}/" ${template_slurm} \
	        | sed "s/NUM_NODES/${num_nodes}/" \
			    > ${slurm_script}

run_cmd="sbatch ${slurm_script} mpt_distributed_docker.sh"
echo "${run_cmd}"
eval "${run_cmd}"

rm -f ${slurm_script}

set +x
