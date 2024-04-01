from sqlalchemy import create_engine, MetaData, Table, select, join
import os
import json

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
        j = join(requests, paths,
                requests.c.path_id == paths.c.path_id)
        request_query = select(
            requests.c.status,
            paths.c.path_desc, 
            paths.c.number_of_moves, 
            paths.c.starting, 
            paths.c.ending, 
            requests.c.request_id
            ).select_from(j).where(requests.c.request_id == operation_id)
        request_result = conn.execute(request_query)
        request_row = request_result.fetchone()

        try:
            status, path_desc, number_of_moves, starting, ending, request_id = request_row

            if status == 'COMPLETE':
                return {
                    'statusCode': 200,
                    'body': json.dumps({
                        'status': status,
                        "starting": starting,
                        "ending": ending,
                        "shortestPath": path_desc,
                        "numberOfMoves": number_of_moves,
                        "operationId": request_id
                    })
                }
            else:
                return {
                    'statusCode': 200,
                    'body': f"Request status: {status}"
                }
        except Exception as e:
            return {
                    'statusCode': 422,
                    'body': "Query ID not found."
                }