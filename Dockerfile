FROM pytorch/pytorch:1.11.0-cuda11.3-cudnn8-runtime
## Working directory
# cannot freely modify as it is related to data dir
WORKDIR /workspace/disttrain

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
