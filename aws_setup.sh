#!/bin/bash

# Set up dev server

set -x

install_nvidia_driver=false
install_docker=false
install_venv=false
login_ecr=false
build_docker_image=false
install_software=false
submit_batch=false

# === Set up machine overall === #

# https://phoenixnap.com/kb/how-to-install-docker-on-ubuntu-18-04
if [ "$install_docker" = true ]
then
    sudo apt-get update
    sudo apt-get remove docker docker-engine docker.io
    sudo apt install docker.io
    sudo systemctl start docker
    sudo systemctl enable docker
    docker --version
    # https://www.digitalocean.com/community/questions/how-to-fix-docker-got-permission-denied-while-trying-to-connect-to-the-docker-daemon-socket
    sudo chmod 666 /var/run/docker.sock
fi


if [ "$install_nvidia_driver" = true ]
then
    # if need a purge and fix: https://askubuntu.com/questions/753923/nvidia-smi-hangs-cannot-be-killed-even-by-sigkill
    sudo add-apt-repository ppa:graphics-drivers/ppa
    sudo apt-get update
    sudo apt install -y nvidia-driver--470
    sudo reboot !!!
    sudo nvidia-smi -pm 1
fi

# https://forums.developer.nvidia.com/t/could-not-select-device-driver-with-capabilities-gpu/194834/5
# https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/install-guide.html
if [ "$install_nvidia_container_toolkit" = true ]
    distribution=$(. /etc/os-release;echo $ID$VERSION_ID) \
      && curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | sudo gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg \
      && curl -s -L https://nvidia.github.io/libnvidia-container/$distribution/libnvidia-container.list | \
            sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' | \
            sudo tee /etc/apt/sources.list.d/nvidia-container-toolkit.list
    sudo apt-get update
    sudo apt-get install -y nvidia-docker2
    sudo systemctl restart docker
    # check
    sudo docker run --rm --gpus all nvidia/cuda:11.0-base nvidia-smi
then

# === Set up development environement === #

# install venv and use python3.8 for development environment
# update to python3.8 ONLY for virtualenv
# DON'T EVER CHANGE DEFAULT PYTHON!!!
# https://askubuntu.com/questions/1197683/how-do-i-install-python-3-8-in-lubuntu-18-04
# If need to update python version: https://tech.serhatteker.com/post/2019-12/upgrade-python38-on-ubuntu/
if [ "$install_venv" = true ]
then
    # sudo apt-get install python3-venv
    sudo apt-get install python3.8 python3.8-dev python3.8-distutils python3.8-venv
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
    docker build -f Dockerfile -t charnn:latest ./
    docker tag charnn:latest $ECR_URL:charnn
    docker push $ECR_URL:charnn
fi

if [ "$install_software" = true ]
then
    # everything needed to run charnn locally
    pip3 install -r requirements.txt
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
fi

if [ "$submit_batch" = true ]
then
    AWS_DEFAULT_REGION=us-west-2 \
    torchx run --workspace "" -s aws_batch -cfg queue=torchx-gpu dist.ddp \
    --script apps/charnn/main.py --image $ECR_URL:charnn --cpu 4 --gpu 4 -j 2x4
fi

deactivate