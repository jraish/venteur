FROM public.ecr.aws/lambda/python:3.12
COPY requirements.txt ${LAMBDA_TASK_ROOT}
RUN python -m pip install --upgrade pip
RUN pip install psycopg2-binary
RUN pip install -r requirements.txt
COPY app.py ${LAMBDA_TASK_ROOT}
CMD [ "app.lambda_handler" ]