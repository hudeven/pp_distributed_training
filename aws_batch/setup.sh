#!/bin/bash

# Set up dev server

set -x

run_mode="local_torchx"


python3 -c "import torch; torch.cuda.is_available()"

if [ "$run_mode" = "local_torchx" ]
then
    torchx run --workspace "" -s local_docker dist.ddp \
        --script apps/charnn/main.py --image charnn:latest --cpu 4 --gpu 4 -j 1x4
elif [ "$run_mode" = "local_elastic_gpu" ]
then
    docker run --rm --gpus all charnn:latest torchrun --standalone --nnodes=1 --nproc_per_node=2 apps/charnn/main.py
elif [ "$run_mode" = "local_elastic_cpu" ]
then
    docker run charnn:latest torchrun apps/charnn/main.py
elif ["$run_mode" = "local_interactive" ]
then
    docker run -it --rm --gpus all charnn:latest /bin/bash
    # then run 
    # torchrun --standalone --nnodes=1 --nproc_per_node=2 apps/charnn/main.py
elif [ "$run_mode" = "submit_batch" ]
then
    AWS_DEFAULT_REGION=us-west-2 \
    torchx run --workspace "" -s aws_batch -cfg queue=torchx-gpu dist.ddp \
    --script apps/charnn/main.py --image $ECR_URL:charnn --cpu 4 --gpu 4 -j 2x4
fi

deactivate