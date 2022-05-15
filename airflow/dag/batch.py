from datetime import timedelta
import logging
from airflow import DAG
from airflow.operators.bash import BashOperator
from airflow.utils.dates import days_ago
default_args = {
    'owner': 'airflow',
    'depends_on_past': False,
    'email': ['dracifer@gmail.com'],
    'email_on_failure': True,
    'email_on_retry': False,
    'retries': 0,
    'retry_delay': timedelta(minutes=5),
}
dag = DAG(
    'aws_batch_demo',
    default_args=default_args,
    description='A simple DAG with submitting Batch Job.',
    schedule_interval=timedelta(days=1),
    start_date=days_ago(2),
    tags=['aws_batch'],
)
# PYTHON FUNCTIONS


# bash operator for prototyping
# For real prod, should use python API instead 
t1 = BashOperator(
    task_id="charnn_batch",
    bash_command="AWS_DEFAULT_REGION=us-west-2 \
    torchx run --workspace '' -s aws_batch \
    -cfg queue=torchx-gpu,image_repo=$ECR_URL dist.ddp \
    --script apps/charnn/main.py --image $ECR_URL:charnn --cpu 4 --gpu 4 -j 2x4 \
    --memMB 20480 --env NCCL_SOCKET_IFNAME=eth0 2>&1 \
    | grep -Eo 'aws_batch://torchx/torchx-gpu:main-[a-z0-9]+'",
    dag=dag,
    do_xcom_push=True,
)

t2 = BashOperator(
    task_id="parse_output",
    bash_command="echo {{ ti.xcom_pull(task_ids='charnn_batch') }}",
    dag=dag,
)

t1 >> t2
