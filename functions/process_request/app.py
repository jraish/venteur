from sqlalchemy import create_engine, MetaData, Table, select, update
import os

DB_USER = os.getenv('DB_USER')
DB_PASSWORD = os.getenv('DB_PASSWORD')
DB_HOST = os.getenv('DB_HOST')
DB_DATABASE = os.getenv('DB_DATABASE')

valid_files = ['A','B','C','D','E','F','G','H']
valid_ranks = ['1','2','3','4','5','6','7','8']

chessboard = [({a},{b}) for a in valid_files for b in valid_ranks]

class Edge:
    def __init__(self, start, finish) -> None:
        self.start = start,
        self.finish = finish

class Path:
    def __init__(self) -> None:
        self.edges = []
        self.length = 0

def check_valid_square(chess_square):
    return (
        len(str(chess_square)) == 2 
        and str(chess_square)[0] in valid_files
        and str(chess_square)[1] in valid_ranks
    )

# def find_knights_path(start, finish, paths):
#     visited_squares = {start}




def lambda_handler(event, context):
    query_params = event.get('queryStringParameters')
    request_id = query_params.get('request_id') if query_params else event.get('request_id')
    source = query_params.get('source') if query_params else event.get('source')
    target = query_params.get('target') if query_params else event.get('target')

    if not (request_id and source and target):
        return {
                'statusCode': 422,
                'body': 'Request must contain request, source, and target.'
            }

    engine = create_engine(f"postgresql+psycopg2://{DB_USER}:{DB_PASSWORD}@{DB_HOST}/{DB_DATABASE}")
    metadata = MetaData()
    requests = Table('request', metadata, autoload_with=engine)

    with engine.connect() as conn:
        update_query = (
            update(requests)
            .where(requests.c.request_id == request_id)
            .values(status='IN PROGRESS')
        )
        conn.execute(update_query)
        conn.commit()

    
    
    return {
        'statusCode': 200,
        'body': f"Request complete"
    }