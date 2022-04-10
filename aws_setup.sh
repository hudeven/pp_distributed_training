#!/bin/bash

set -x

install_docker=false
install_venv=false
login_ecr=false
build_docker_image=false
install_torchx=false
submit_batch=false
install_nvidia_driver=false

if [ "$install_nvidia_driver" = true ]
then
    # if need a purge and fix: https://askubuntu.com/questions/753923/nvidia-smi-hangs-cannot-be-killed-even-by-sigkill
    sudo add-apt-repository ppa:graphics-drivers/ppa
    sudo apt-get update
    sudo apt install -y nvidia-driver--470
    sudo reboot !!!
    sudo nvidia-smi -pm 1
fi

if [ "$install_venv" = true ]
then
    # sudo apt-get install python3-venv
    sudo apt-get install python3.8 python3.8-dev python3.8-distutils python3.8-venv
    python3.8 -m venv env
fi

# https://phoenixnap.com/kb/how-to-install-docker-on-ubuntu-18-04
if [ "$install_docker" = true ]
then
    sudo apt-get update
    sudo apt-get remove docker docker-engine docker.io
    sudo apt install docker.io
    sudo systemctl start docker
    sudo systemctl enable docker
    docker --version
fi

if [ "$login_ecr" = true ]
then
    # Dev server: awsume api 495572122715 SSOAdmin
    # https://www.digitalocean.com/community/questions/how-to-fix-docker-got-permission-denied-while-trying-to-connect-to-the-docker-daemon-socket
    sudo chmod 666 /var/run/docker.sock
    aws ecr get-login-password --region us-west-2 | docker login --username AWS --password-stdin $ECR_URL
fi 

# update to python3.8 ONLY for virtualenv
# DON'T EVER CHANGE DEFAULT PYTHON!!!
# https://askubuntu.com/questions/1197683/how-do-i-install-python-3-8-in-lubuntu-18-04
# If need to update python version: https://tech.serhatteker.com/post/2019-12/upgrade-python38-on-ubuntu/

source env/bin/activate

if [ "$build_docker_image" = true ]
then
    docker build -f Dockerfile -t charnn:latest ./
    docker tag charnn:latest $ECR_URL:charnn
    docker push $ECR_URL:charnn
fi

if [ "$install_torchx" = true ]
then
    pip3 install -r requirements.txt
    pip3 install torchx
    pip3 install boto3 # AWS SDK for Python: https://aws.amazon.com/sdk-for-python/
fi

if [ "$submit_batch" = true ]
then
    AWS_DEFAULT_REGION=us-west-2 \
    torchx run --workspace "" -s aws_batch -cfg queue=torchx-gpu dist.ddp \
    --script charnn/main.py --image $ECR_URL:charnn --cpu 4 --gpu 4 -j 2x4
fi

# check cuda
# nvidia-smi
# python3 -c "import torch; torch.cuda.is_available()"

deactivate