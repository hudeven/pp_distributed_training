import mlflow
import functools
from torch import distributed as dist
import torch
from typing import Optional
import time    
import logging
import os
import atexit

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


def rank_0_only(func):

    @functools.wraps(func)
    def wrapper(*args, **kwargs):
        rank, _ = get_dist_info()
        if rank == 0:
            return func(*args, **kwargs)

    return wrapper

def optional_class(switch_arg):
    def decorator(Cls):
        class OptionalClass:
            def __init__(self, *args, **kwargs):
                self.switch_off = kwargs.get(switch_arg, None) is None
                if not self.switch_off:
                    self.decorated_obj = Cls(*args, **kwargs)

            def __getattribute__(self, s):
                try:
                    return super().__getattribute__(s)
                except AttributeError:
                    pass

                if self.switch_off:
                    logger.info(f"switched off {s}")
                    
                    def dummy_f(*args, **kwargs):
                        return
                    return dummy_f
                return self.decorated_obj.__getattribute__(s)

        return OptionalClass  # decoration ends here

    return decorator



@optional_class(switch_arg="experiment_name")
class MlflowLogger:
    def __init__(
        self,
        experiment_name: Optional[str],
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
        atexit.register(self.end)
    
    @rank_0_only
    def log_param_dataclass(self, dc) -> None:
        for field in dc.__dataclass_fields__.keys():
            mlflow.log_param(field, getattr(dc, field))

    @rank_0_only
    def log_model(self, model: torch.nn.Module, name: str = "model") -> None:
        mlflow.pytorch.log_model(model, name)

    def log_metric(self, name, val, step) -> None:
        mlflow.log_metric(name, val, step)

    def end(self) -> None:
        mlflow.end_run()