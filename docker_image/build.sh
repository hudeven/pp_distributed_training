#!/bin/bash

set -x

docker build -f docker_image/Dockerfile -t charnn:latest ./ --build-arg aws=true # --no-cache
docker tag charnn:latest $ECR_URL:charnn
docker push $ECR_URL:charnn