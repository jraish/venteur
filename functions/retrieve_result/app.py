from sqlalchemy import create_engine, MetaData, Table, select
import os

DB_USER = os.getenv('DB_USER')
DB_PASSWORD = os.getenv('DB_PASSWORD')
DB_HOST = os.getenv('DB_HOST')
DB_DATABASE = os.getenv('DB_DATABASE')

def lambda_handler(event, context):
    query_params = event.get('queryStringParameters')
    operation_id = query_params.get('operationId') if query_params else event.get('operationId')
        
    if not operation_id:
        return {
                'statusCode': 422,
                'body': 'Request must contain an operation ID.'
            }

    engine = create_engine(f"postgresql+psycopg2://{DB_USER}:{DB_PASSWORD}@{DB_HOST}/{DB_DATABASE}")
    metadata = MetaData()
    requests = Table('request', metadata, autoload_with=engine)
    paths = Table('path', metadata, autoload_with=engine)

    with engine.connect() as conn:
        request_query = select(requests).where(requests.c.request_id == operation_id)
        request_result = conn.execute(request_query)
        request_row = request_result.fetchone()

        _, status, path_id, message = request_row

    if status == 'COMPLETE':
        return {
            'statusCode': 200,
            'body': f"Request complete! Path ID: {path_id}"
        }
    else:
        return {
            'statusCode': 200,
            'body': f"Request status: {status}"
        }