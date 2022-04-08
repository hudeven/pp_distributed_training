Repository contains examples of distributed training jobs with Pytorch.

The models can be trained on single GPU instances as well as in production environment, e.g. SLURM.

# AWS
## AWS Batch
* Overall Set up Instruction https://docs.aws.amazon.com/batch/latest/userguide/get-set-up-for-aws-batch.html

### CLI 


### CharNN

The model is a simple minGPT model that supports the following features:

* DDP trainig on a single or multiple nodes
* Checkpointing
* Metrics logging with tensorboard
* Profiling support
* Job configuration via Hydra

Executing single process:

```bash
pip install -r requirements.txt
python charnn/main.py
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
