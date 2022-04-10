FROM python:3.8-buster
## Working directory
WORKDIR /app

COPY ./requirements.txt ./
## Install Requirements
RUN pip3 install wheel
RUN pip3 install setuptools==59.5.0
RUN pip3 install -r requirements.txt
## Copy script
COPY ./* ./

# docker run -it charnn:latest /bin/bash
#   Does not seem to work -- much slower than `torchrun charnn/main.py`
#   torchrun --standalone --nnodes=1 --nproc_per_node=2 charnn/main.py
