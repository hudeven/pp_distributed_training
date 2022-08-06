from datetime import timedelta
import logging
from airflow import DAG
from airflow.operators.python import PythonOperator
import pendulum


default_args = {
    'owner': 'airflow',
    'depends_on_past': False,
    'email': ['dracifer@gmail.com'],
    'email_on_failure': True,
    'email_on_retry': False,
    'retries': 1,
    'retry_delay': timedelta(minutes=5),
}
dag = DAG(
    'simple_demo',
    default_args=default_args,
    description='A simple DAG with a few Python tasks.',
    schedule_interval=timedelta(days=1),
    start_date=pendulum.today('UTC').add(days=-2),
    tags=['example'],
)
# PYTHON FUNCTIONS


def log_context(**kwargs):
    for key, value in kwargs.items():
        logging.info(f"Context key {key} = {value}")


def compute_product(a=None, b=None):
    print(f"Inputs: a={a}, b={b}")
    logging.info(f"Inputs: a={a}, b={b}")
    if a == None or b == None:
        return None
    return a * b


# OPERATORS
t1 = PythonOperator(
    task_id="task1",
    python_callable=log_context,
    dag=dag
)
t2 = PythonOperator(
    task_id="task2",
    python_callable=compute_product,
    op_kwargs={'a': 3, 'b': 5},
    dag=dag
)
t1 >> t2

print("done")
