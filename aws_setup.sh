#!/bin/bash

set -x

install_docker=false
install_venv=false
login_ecr=false
build_docker_image=false
install_torchx=false
submit_batch=false

if [ "$install_venv" = true ]
then
    # sudo apt-get install python3-venv
    sudo apt-get install python3.8 python3.8-dev python3.8-distutils python3.8-venv
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
python3.8 -m venv env
source env/bin/activate

if [ "$build_docker_image" = true ]
then
    docker build -f Dockerfile -t charnn:latest ./
    docker tag charnn:latest $ECR_URL/bwen:charnn
    docker push $ECR_URL/bwen:charnn
fi

if [ "$install_torchx" = true ]
then
    pip3 install wheel
    pip3 install torch 
    pip3 install torchx
    pip3 install boto3
fi

if [ "$submit_batch" = true ]
then
    AWS_DEFAULT_REGION=us-west-2 \
    torchx run --workspace "" -s aws_batch -cfg queue=torchx-gpu dist.ddp \
    --script apps/charnn/main.py --image $ECR_URL/bwen:charnn --cpu 4 --gpu 4 -j 2x4
fi

deactivate