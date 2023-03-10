FROM public.ecr.aws/docker/library/python:3.9.16-bullseye

COPY requirements.txt .

RUN pip install -r requirements.txt

COPY main.py .

CMD ["python3", "main.py"]