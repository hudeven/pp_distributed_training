#!/bin/bash

install_airflow=false
start_local_airflow=false

if [ "$install_airflow" = true ]
then
    pip3 install --upgrade pip
    sudo apt install libffi-dev
    pip3 install setuptools-rust
    pip3 install "apache-airflow[celery]==2.3.0" --constraint "https://raw.githubusercontent.com/apache/airflow/constraints-2.3.0/constraints-3.7.txt"
    pip3 boto3
fi

# https://airflow.apache.org/docs/apache-airflow/stable/start/local.html
if [ "$start_local_airflow" = true ]
then
    airflow standalone
fi


aws s3 cp test.py s3://charnn-data/airflow/test.py