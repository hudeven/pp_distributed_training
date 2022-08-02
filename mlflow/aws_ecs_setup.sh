#!/bin/bash

# Set up MLFlow server on EC2
# https://aws.plainenglish.io/set-up-mlflow-on-aws-ec2-using-docker-s3-and-rds-90d96798e555

# This commands in this script are run on dev server
set -x

build_docker_image=true
login_ecr=true

if [ "$login_ecr" = true ]
then
# Dev server: awsume api 495572122715 SSOAdmin
# Copy-past credential envs
    aws ecr get-login-password --region us-west-2 | docker login --username AWS --password-stdin $ECR_URL
fi

source env/bin/activate

# export ECR_URL=<ERC repo URL>
if [ "$build_docker_image" = true ]
then
    docker build -f Dockerfile -t mlflow_server:latest ./
    docker tag mlflow_server:latest $ECR_URL/mlflow_server:latest
    docker push $ECR_URL/mlflow_server:latest
fi

# check which port is listening
curl ifconfig.me
sudo lsof -i -P -n | grep LISTEN

deactivate


# Set up ECS manually https://www.youtube.com/watch?v=zs3tyVgiBQQ
# <public_dns>:8888/#/ -- IMPORTANT -- DO NOT include http or https!

# If start docker on standalone EC2 instance, remember to bind port with -p !!
# docker run --name mlflow-tracking -p 5000:5000 mlflow_server:latest
