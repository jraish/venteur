from sqlalchemy import create_engine, MetaData, Table
import os
import uuid
import boto3
import json

DB_USER = os.getenv('DB_USER')
DB_PASSWORD = os.getenv('DB_PASSWORD')
DB_HOST = os.getenv('DB_HOST')
DB_DATABASE = os.getenv('DB_DATABASE')

valid_files = ['A','B','C','D','E','F','G','H']
valid_ranks = ['1','2','3','4','5','6','7','8']

def check_valid_square(chess_square):
    return (
        len(str(chess_square)) == 2 
        and str(chess_square)[0] in valid_files
        and str(chess_square)[1] in valid_ranks
    )

def lambda_handler(event, context):
    query_params = event.get('queryStringParameters')
    source = query_params.get('source') if query_params else event.get('source')
    target = query_params.get('target') if query_params else event.get('target')

    if (
        not (source and target) 
        or not check_valid_square(source) 
        or not check_valid_square(target)
    ):
        return {
                'statusCode': 422,
                'body': f'Request must include "source" and "target" valid chess squares. Source: {source}, target: {target}'
            }
    
    engine = create_engine(f"postgresql+psycopg2://{DB_USER}:{DB_PASSWORD}@{DB_HOST}/{DB_DATABASE}")
    metadata = MetaData()
    requests = Table('request', metadata, autoload_with=engine)
    request_id = str(uuid.uuid4())

    lambda_client = boto3.client('lambda')

    function_name = 'process_request_lambda'
    payload = {
        'request_id': request_id,
        'source': source,
        'target': target
    }

    response = lambda_client.invoke(
        FunctionName=function_name,
        InvocationType='Event',
        Payload=json.dumps(payload)
    )

    response_payload = json.load(response['Payload'])

    with engine.connect() as conn:
        trans = conn.begin()

        new_request = {
            'request_id': request_id,
            'status': 'RECEIVED',
            'path_id': f'{source},{target}',
            'message': ''
        }
        conn.execute(requests.insert().values(**new_request))
        trans.commit()
    
    return {
        'statusCode': 200,
        'body': f"Request submitted! Request ID: {request_id}"
    }   
