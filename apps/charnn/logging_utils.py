import mlflow
import functools
from torch import distributed as dist
import torch
from typing import Optional
import time    
import logging

logger = logging.getLogger(__name__)

def get_dist_info():
    if dist.is_available():
        initialized = dist.is_initialized()
    else:
        initialized = False
    if initialized:
        rank = dist.get_rank()
        world_size = dist.get_world_size()
    else:
        rank = 0
        world_size = 1
    return rank, world_size


def master_only(func):

    @functools.wraps(func)
    def wrapper(*args, **kwargs):
        rank, _ = get_dist_info()
        if rank == 0:
            return func(*args, **kwargs)

    return wrapper

class MlflowLogger:
    def __init__(
        self,
        experiment_name: str,
        mlflow_server_url: Optional[str],
    ) -> None: 
        self._rank, self._world_size = get_dist_info()
        if mlflow_server_url:
            mlflow.set_tracking_uri(mlflow_server_url)
        if not mlflow.get_experiment_by_name(experiment_name):
            try:
                mlflow.create_experiment(name=experiment_name) 
            except Exception as ex:
                logger.warning(ex)

        experiment = mlflow.get_experiment_by_name(experiment_name)
        mlflow.start_run(
            experiment_id=experiment.experiment_id, 
            run_name=f"{int(time.time())}.rank{self._rank}",
        )
    
    @staticmethod
    @master_only
    def log_param_dataclass(dc) -> None:
        for field in dc.__dataclass_fields__.keys():
            mlflow.log_param(field, getattr(dc, field))

    @staticmethod
    @master_only
    def log_model(model: torch.nn.Module) -> None:
        mlflow.pytorch.log_model(model, "model")

    def __del__(self) -> None:
        mlflow.end_run()