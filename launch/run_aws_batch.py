#!/bin/bash

# Set up dev server

set -x

run_mode="local_torchx"

# source env/bin/activate

python3 -c "import torch; torch.cuda.is_available()"

# NOTE: we do not provide temp credentials if IAM instanceRole for 
#       EC2 are appropriately set with the correct permissions
#  --env AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID \
#  --env AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY \
#  --env AWS_SESSION_TOKEN=$AWS_SESSION_TOKEN \
if [ "$run_mode" = "local_interactive" ] 
then
    docker run -it --rm --gpus all charnn:latest /bin/bash

    # then run 
    # torchrun --standalone --nnodes=1 --nproc_per_node=2 apps/charnn/main.py
elif [ "$run_mode" = "local_torchx" ]
then
    # takes a very long time to get console work
    # if resource is not sufficient, will fail without much usefo info
    torchx run --workspace "" -s local_docker dist.ddp \
        --script apps/charnn/main.py --image $ECR_URL:charnn --cpu 4 --gpu 2 -j 1x2 --memMB 20480 \
        --env NCCL_SOCKET_IFNAME=eth0
elif [ "$run_mode" = "local_elastic_gpu" ]
then
    docker run --rm --gpus all \
    charnn:latest torchrun --standalone --nnodes=1 --nproc_per_node=2 apps/charnn/main.py
elif [ "$run_mode" = "local_elastic_cpu" ]
then
    docker run charnn:latest torchrun apps/charnn/main.py
elif [ "$run_mode" = "submit_batch" ]
then
    AWS_DEFAULT_REGION=us-west-2 \
    torchx run --workspace "" -s aws_batch \
    -cfg queue=torchx-gpu,image_repo=$ECR_URL dist.ddp \
    --script apps/charnn/main.py --image $ECR_URL:charnn --cpu 4 --gpu 4 -j 2x4 \
    --memMB 20480 --env NCCL_SOCKET_IFNAME=eth0
    # to add debugging: --env NCCL_DEBUG=INFO,LOGLEVEL=INFO
fi

## Tips
# Get large files: sudo find / -type f -size +1G -exec ls -lh {} \;
# Get disk usage: df -h

# deactivate