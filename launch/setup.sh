#!/bin/bash

# Set up environement needed to launch the job
# It applies to devserver and servers need to lauch the job

set -x

init_venv=false
login_ecr=false
build_docker_image=false
install_software=false
submit_batch=false
install_torchdata_s3=false

run_mode="local_torchx"

# === Set up launching environement === #

# export ECR_URL to ~/.bashrc

if [ "$login_ecr" = true ]
then
    echo $ECR_URL
    # Dev server: awsume api 495572122715 SSOAdmin
    # Needed in order to push docker image to ECR
    aws ecr get-login-password --region us-west-2 | docker login --username AWS --password-stdin $ECR_URL
fi 

# start virtualenvironment
source ../../env/bin/activate

if [ "$install_software" = true ]
then
    pip3 install wheel
    # Submit dist job with torchx
    pip3 install torchx-nightly[dev]
fi


# export ECR_URL=<ERC repo URL>
if [ "$build_docker_image" = true ]
then
    cd ../
    docker_image/build.sh
    docker images
    cd setup_local
fi


## Tips
# Get large files: sudo find / -type f -size +1G -exec ls -lh {} \;
# Get disk usage: df -h


# # Not required as current torch.data s3 support leverages fsspec
# if [ "$install_torchdata_s3" = true ]
# then
#     # Install TorchData with EC2 official support
#     # Set up EC2: https://github.com/aws/aws-sdk-cpp/wiki/Building-the-SDK-from-source-on-EC2 
#     sudo apt install g++ cmake -y
#     sudo apt install zlib1g-dev libssl-dev libcurl4-openssl-dev -y
#     # Install https://github.com/pytorch/data/tree/main/torchdata/datapipes/iter/load#readme
#     git clone --recurse-submodules https://github.com/aws/aws-sdk-cpp
#     cd aws-sdk-cpp/
#     mkdir sdk-build
#     cd sdk-build
#     cmake .. -DCMAKE_BUILD_TYPE=Release -DBUILD_ONLY="s3;transfer"
#     make
#     sudo make install 
#     pip3 install ninja pybind11

#     cd ../..
#     git clone --recurse-submodules https://github.com/pytorch/data.git
#     cd data
#     cd ..
#     export BUILD_S3=ON
#     pip3 uninstall torchdata -y
#     python3 setup.py clean
#     python3 setup.py install
# fi

deactivate