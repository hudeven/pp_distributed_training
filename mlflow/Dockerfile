FROM python:3.8.8

RUN apt-get update
RUN apt-get install -y python3-pip
RUN pip3 install mlflow==1.24.0 boto3

WORKDIR /mlflow
EXPOSE 5000

ENV STORAGE_URL s3://bwen-mlflow-artifacts

CMD mlflow server --backend-store-uri ./mlruns --default-artifact-root $STORAGE_URL/mlflow_artifacts/ --host 0.0.0.0 --port 5000