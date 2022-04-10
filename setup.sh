#!/bin/bash

# Set up dev server

set -x

init_venv=false
login_ecr=false
build_docker_image=false
install_software=false
submit_batch=false

# === Set up development environement === #

# install venv and use python3.8 for development environment
# update to python3.8 ONLY for virtualenv
# DON'T EVER CHANGE DEFAULT PYTHON!!!
# https://askubuntu.com/questions/1197683/how-do-i-install-python-3-8-in-lubuntu-18-04
# If need to update python version: https://tech.serhatteker.com/post/2019-12/upgrade-python38-on-ubuntu/
if [ "$init_venv" = true ]
then
    python3.8 -m venv env
fi

if [ "$login_ecr" = true ]
then
    # Dev server: awsume api 495572122715 SSOAdmin
    aws ecr get-login-password --region us-west-2 | docker login --username AWS --password-stdin $ECR_URL
fi 

# start virtualenvironment
source env/bin/activate

# export ECR_URL=<ERC repo URL>
if [ "$build_docker_image" = true ]
then
    docker build -f ./Dockerfile -t charnn:latest ./ # --no-cache
    docker tag charnn:latest $ECR_URL:charnn
    docker push $ECR_URL:charnn
fi

if [ "$install_software" = true ]
then
    # everything needed to run charnn locally
    pip3 install -r ./requirements.txt
    # Submit dist job with torchx
    pip3 install torchx
    # AWS SDK for Python: https://aws.amazon.com/sdk-for-python/
    pip3 install boto3 
fi

if [ "$start_local_run" = true ]
then
    # check cuda
    nvidia-smi
    python3 -c "import torch; torch.cuda.is_available()"
    torchx run --workspace "" -s local_docker dist.ddp \
        --script apps/charnn/main.py --image $ECR_URL:charnn --cpu 4 --gpu 4 -j 1x4
    # OR interactive mode
    # docker run -it --rm --gpus all charnn:latest /bin/bash
    # torchrun --standalone --nnodes=1 --nproc_per_node=2 apps/charnn/main.py
fi

if [ "$submit_batch" = true ]
then
    AWS_DEFAULT_REGION=us-west-2 \
    torchx run --workspace "" -s aws_batch -cfg queue=torchx-gpu dist.ddp \
    --script apps/charnn/main.py --image $ECR_URL:charnn --cpu 4 --gpu 4 -j 2x4
fi

deactivate