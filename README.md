Repository contains examples of distributed training jobs with Pytorch.

The models can be trained on single GPU instances as well as in production environment, e.g. SLURM/AWS Batch.

# AWS
## Set an EC2 Instance and dev server
1. Overall Set up Instruction https://docs.aws.amazon.com/batch/latest/userguide/get-set-up-for-aws-batch.html
  * Config AWS, IAM, Key Pair, VPC, Security Group
2. Get an EC2 instance as remote dev machine

```bash
cd devserver
```
follow `aws_setup.sh`

## AWS Batch
1. Create Batch through Wizard: https://docs.aws.amazon.com/batch/latest/userguide/Batch_GetStarted.html
  * NOTE: 
    * The instruction order is messed on the web.  
    * Configure Compute Environment and Job Queue. Do not need to Define Job if launch with torch.x

```bash
cd aws_batch
```

Details in `setup.sh` if run Batch

# MLflow tracking server
Set up and start mlflow tracking service

```bash
cd mlflow
```
Details in `aws_ecs_setup.sh` if run Batch

# Apps/Models
## CharNN

The model is a simple minGPT model that supports the following features:

* DDP trainig on a single or multiple nodes
* Checkpointing
* Metrics logging with tensorboard
* Profiling support
* Job configuration via Hydra

Executing single process:

```bash
pip install -r requirements.txt
python apps/charnn/main.py
```

Executing single process with torch elastic under Docker image env:
```bash
cd aws_batch
docker build -f Dockerfile -t charnn:latest ./
docker run -it charnn:latest /bin/bash
torchrun apps/charnn/main.py
```

Running on multiple GPUs on a single host:

```bash
torchrun --nnodes 1 --nproc_per_node 4 \
--rdzv_backend c10d \
--rdzv_endpoint localhost:29500 apps/charnn/main.py
```

Run with checkpoint:

```bash
mkdir -p logs/tb

torchrun --nnodes 1 --nproc_per_node 4 \
--rdzv_backend c10d \
--rdzv_endpoint localhost:29500 apps/charnn/main.py \
+trainer.checkpoint_path=./logs/model.pt \
+trainer.log_dir=./logs/tb
```

Setting up SLURM cluster and executing job in [SLURM](slurm/README.md)
