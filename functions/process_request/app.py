from sqlalchemy import create_engine, MetaData, Table
from sqlalchemy.sql.expression import select
import os
import json
import logging
import queue

DB_USER = os.getenv('DB_USER')
DB_PASSWORD = os.getenv('DB_PASSWORD')
DB_HOST = os.getenv('DB_HOST')
DB_DATABASE = os.getenv('DB_DATABASE')

logger = logging.getLogger()

square_dict = {a:'ABCDEFGH'[a - 1] for a in range(1,9)}

def tuple_to_square_key(sq_tuple):
    return f"{square_dict[sq_tuple[0]]}{sq_tuple[1]}"

def square_key_to_tuple(sq_key):
    return ('ABCDEFGH'.index(sq_key[0]) + 1,int(sq_key[1]))

class KnightPath:
    def __init__(self, path = [], length = 0):
        self.path = path
        self.length = length
    
    def get_description(self):
        return ":".join([tuple_to_square_key(square) for square in self.path])
    
    def create_new_path(self, square):
        return KnightPath(self.path + [square], self.length + 1)
    
    def get_next_squares(self):
        x, y = self.path[-1]
        return [(x+dx,y+dy)
            for h,v   in [(1,2),(2,1)] 
            for dx,dy in [(h,v),(h,-v),(-h,v),(-h,-v)]
            if x+dx in range(1,9) and y+dy in range(1,9) ]

    def get_current_square(self):
        return tuple_to_square_key(self.path[-1])

def find_knights_path(source, target):
    visited_squares = {square_key_to_tuple(source)}
    to_visit_queue: queue.Queue[KnightPath] = queue.Queue()

    to_visit_queue.put(KnightPath(path=[square_key_to_tuple(source)], length=0))

    while not to_visit_queue.empty():
        current_path = to_visit_queue.get()
        if current_path.get_current_square() == target:
            return {
                "status": "FOUND",
                "path": current_path
            }
        
        new_squares = current_path.get_next_squares()
        for square in new_squares:
            if square not in visited_squares:
                visited_squares.add(square)
                to_visit_queue.put(current_path.create_new_path(square))

    return {
            "status": "PATH NOT FOUND",
            "path": None
        }

def lambda_handler(event, context):
    for record in event.get('Records'):
        message = json.loads(record.get('body'))    
        if not message:
            logger.error('Message empty')
            return {
                'statusCode': 422,
                'body': 'Message empty'
            }
        request_id, source, target = message.get('request_id'), message.get('source'), message.get('target')
        
        engine = create_engine(f"postgresql+psycopg2://{DB_USER}:{DB_PASSWORD}@{DB_HOST}/{DB_DATABASE}")
        metadata = MetaData()
        requests = Table('request', metadata, autoload_with=engine)
        paths = Table('path', metadata, autoload_with=engine)

        with engine.connect() as conn:
            trans = conn.begin()
            conn.execute(requests.update().where(requests.c.request_id==request_id).values(status='IN PROGRESS'))
            trans.commit()
            
            paths_query = conn.execute(select(paths.c.path_id, paths.c.number_of_moves))
            existing_path_dict = {row[0]:row[1] for row in paths_query.fetchall()}

        if f'{source},{target}' not in existing_path_dict:
            result = find_knights_path(
                source, 
                target
                )
            if result["status"] == "FOUND":
                knight_path: KnightPath = result["path"]
                with engine.connect() as conn:
                    trans = conn.begin()
                    conn.execute(
                        paths.insert().values(
                            path_id=f'{source},{target}',
                            starting=source,
                            ending=target,
                            number_of_moves=knight_path.length,
                            path_desc=knight_path.get_description()
                        )
                    )
                    trans.commit()   
            else:
                return {
                    'statusCode': 500,
                    'body': 'Path could not be found!'
                }

        with engine.connect() as conn:
            trans = conn.begin()
            conn.execute(requests.update().where(requests.c.request_id==request_id).values(
                status='COMPLETE',
                path_id=f'{source},{target}'
                )
            )
            trans.commit()   

    return {
        'statusCode': 200,
        'body': f"Request complete"
    }