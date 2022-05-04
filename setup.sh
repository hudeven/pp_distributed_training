#!/bin/bash

# Set up dev server

set -x

init_venv=false
login_ecr=false
build_docker_image=false
install_software=false
submit_batch=false
install_torchdata_s3=false

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
    # Needed in order to push docker image to ECR
    aws ecr get-login-password --region us-west-2 | docker login --username AWS --password-stdin $ECR_URL
fi 

# start virtualenvironment
source env/bin/activate

if [ "$install_software" = true ]
then
    # everything needed to run charnn locally
    pip3 install -r ./requirements.txt
    # Submit dist job with torchx
    pip3 install torchx
    # AWS SDK for Python: https://aws.amazon.com/sdk-for-python/
    pip3 install boto3 
fi

if [ "$install_torchdata_s3" = true ]
then
    # Install TorchData with EC2 official support
    # Set up EC2: https://github.com/aws/aws-sdk-cpp/wiki/Building-the-SDK-from-source-on-EC2 
    sudo apt install g++ cmake -y
    sudo apt install zlib1g-dev libssl-dev libcurl4-openssl-dev -y
    # Install https://github.com/pytorch/data/tree/main/torchdata/datapipes/iter/load#readme
    git clone --recurse-submodules https://github.com/aws/aws-sdk-cpp
    cd aws-sdk-cpp/
    mkdir sdk-build
    cd sdk-build
    cmake .. -DCMAKE_BUILD_TYPE=Release -DBUILD_ONLY="s3;transfer"
    make
    sudo make install 
    pip3 install ninja pybind11

    cd ../..
    git clone --recurse-submodules https://github.com/pytorch/data.git
    cd data
    cd ..
    export BUILD_S3=ON
    pip3 uninstall torchdata -y
    python3 setup.py clean
    python3 setup.py install
fi

# export ECR_URL=<ERC repo URL>
if [ "$build_docker_image" = true ]
then
    docker build -f ./Dockerfile -t charnn:latest ./ --build-arg aws=true # --no-cache
    docker tag charnn:latest $ECR_URL:charnn
    docker push $ECR_URL:charnn
fi

deactivate