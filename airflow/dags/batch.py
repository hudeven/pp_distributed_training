from datetime import timedelta
import logging
from airflow import DAG
from airflow.operators.bash import BashOperator
from airflow.operators.python import PythonOperator

import os
import pendulum
from airflow.providers.amazon.aws.hooks.batch_waiters import BatchWaitersHook
import boto3.session

default_args = {
    "owner": "airflow",
    "depends_on_past": False,
    "email": ["dracifer@gmail.com"],
    "email_on_failure": False,
    "email_on_retry": False,
    "retries": 0,
    "retry_delay": timedelta(minutes=5),
}
dag = DAG(
    "aws_batch_demo",
    default_args=default_args,
    description="A simple DAG with submitting Batch Job.",
    schedule_interval="@daily",
    catchup=False,
    start_date=pendulum.today('UTC').add(days=-10),
    tags=["aws_batch"],
    user_defined_macros={
        "ECR_URL": os.environ["ECR_URL"],
    },
)
# PYTHON FUNCTIONS


# bash operator for prototyping
# For real prod, should use python API instead 
t1 = BashOperator(
    task_id="charnn_batch",
    bash_command="AWS_DEFAULT_REGION=us-west-2 \
    torchx run --workspace '' -s aws_batch \
     -cfg queue=torchx-gpu,image_repo={{ ECR_URL }} dist.ddp \
     --script apps/charnn/main.py --image {{ ECR_URL }}:charnn --cpu 4 --gpu 4 -j 2x4 \
     --memMB 20480 --env NCCL_SOCKET_IFNAME=eth0 2>&1 \
     | grep -Eo 'aws_batch://torchx/torchx-gpu:main-[a-z0-9]+'",
    dag=dag,
    do_xcom_push=True,
    # Somehow the following does not work. Maybe due to env is emplated
    # env={
    #     "ECR_URL": "{os.environ['ECR_URL']}",
    # },
)

def wait_for_job(**context) -> bool:
    session = boto3.session.Session()
    client = session.client("batch", region_name="us-west-2")
    job = context["ti"].xcom_pull(task_ids="charnn_batch")
    job_desc = job.split("/")[-1]
    queue_name, job_name = job_desc.split(":")
    job_id = client.list_jobs(
        jobQueue=queue_name, 
        filters=[{"name": "JOB_NAME", "values": [job_name]}],
    )["jobSummaryList"][0]["jobId"]
    print(f"BatchJobID: {job_id}")
    waiter = BatchWaitersHook(region_name="us-west-2")
    try:
        waiter.wait_for_job(job_id)
        return True
    except:
        return False

t2 = PythonOperator(
    task_id="wait_for_batch",
    python_callable=wait_for_job,
    dag=dag,
)

t3 = BashOperator(
    task_id="parse_output",
    bash_command="echo batch result: {{ ti.xcom_pull(task_ids='wait_for_batch') }}",
    dag=dag,
)

t1 >> t2 >> t3
