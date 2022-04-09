FROM python:3.8-buster
## Working directory
WORKDIR /app
COPY ./requirements.txt ./
## Install Requirements
RUN pip3 install -r requirements.txt
## Copy script
COPY ./* ./
## Start
CMD ["python3", "./charnn/main.py"]