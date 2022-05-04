#!/usr/bin/env python3
# Copyright (c) Meta Platforms, Inc. and affiliates.
# All rights reserved.
#
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

import fsspec
from typing import Tuple, Iterator

import torch
from torch.utils.data import Dataset
from torchdata.datapipes.iter import IterDataPipe

def _init_data(self, data_path: str, block_size) -> None:
    fs, path = fsspec.core.url_to_fs(data_path)
    with fs.open(path, "r") as f:
        self.data = f.read()
    self.data_path = data_path
    self.block_size = block_size
    chars = sorted(list(set(self.data)))
    self.data_size = len(self.data)
    self.vocab_size = len(chars)
    print(f"Data has {self.data_size} characters, {self.vocab_size} unique.")
    self.stoi = {ch: i for i, ch in enumerate(chars)}
    self.itos = {i: ch for i, ch in enumerate(chars)}

def _getitem(self, idx: int) -> Tuple[torch.Tensor, torch.Tensor]:
    # grab a chunk of (block_size + 1) characters from the data
    chunk = self.data[idx:idx + self.block_size + 1]
    # encode every character to an integer
    dix = [self.stoi[s] for s in chunk]
    x = torch.tensor(dix[:-1], dtype=torch.long)
    y = torch.tensor(dix[1:], dtype=torch.long)
    return (x, y)

class CharDataset(Dataset):
    def __init__(self, data_path: str, block_size: int) -> None:
        _init_data(self, data_path, block_size)

    def __len__(self) -> int:
        return self.data_size - self.block_size

    def __getitem__(self, idx: int) -> Tuple[torch.Tensor, torch.Tensor]:
        return _getitem(self, idx)


class FSSpecFileReadBatchDataPipe(IterDataPipe[str]):
    def __init__(self, data_path: str, block_size: int) -> None:
        _init_data(self, data_path, block_size)
        self.idx = 0
    def __len__(self):
        return self.data_size - self.batch_size
    def __iter__(self) -> "FSSpecFileReadBatchDataPipe":
        self.idx = 0
        return self
    def __next__(self) -> Tuple[torch.Tensor, torch.Tensor]:
        (x, y) = _getitem(self, self.idx)
        self.idx += self.batch_size
        return (x, y)

def get_dataset(data_path: str, block_size: int, is_dp: bool = False):
    if is_dp:
         return FSSpecFileReadBatchDataPipe(data_path, block_size)
    return CharDataset(data_path, block_size)