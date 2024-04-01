from sqlalchemy import create_engine, MetaData, Table, select, update
import os
import json
import logging

DB_USER = os.getenv('DB_USER')
DB_PASSWORD = os.getenv('DB_PASSWORD')
DB_HOST = os.getenv('DB_HOST')
DB_DATABASE = os.getenv('DB_DATABASE')

logger = logging.getLogger()

square_dict = {a:'ABCDEFGH'[a - 1] for a in range(1,9)}

class KnightPath:
    def __init__(self, path = [], length = 0):
        self.path = path
        self.length = length
    
    def get_description(self):
        return ",".join([f"{square_dict[square[0]]},{square[1]}" for square in self.path])
    
    def create_new_paths(self, square_list):
        return [KnightPath(self.path + [square], self.length + 1) for square in square_list]
    
    def get_next_squares(self):
        x, y = self.path[-1]
        return [(x+dx,y+dy)
            for h,v   in [(1,2),(2,1)] 
            for dx,dy in [(h,v),(h,-v),(-h,v),(-h,-v)]
            if x+dx in range(1,9) and y+dy in range(1,9) ]

def find_knights_path(source, target, engine, path_table, known_paths):
    pass

def get_next_squares():
        x, y = (5,5)
        return ",".join([(x+dx,y+dy)
            for h,v   in [(1,2),(2,1)] 
            for dx,dy in [(h,v),(h,-v),(-h,v),(-h,-v)]
            if x+dx in range(1,9) and y+dy in range(1,9) ])

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
            update_query = (
                update(requests)
                .where(requests.c.request_id == request_id)
                .values(status='IN PROGRESS')
            )
            conn.execute(update_query)
            conn.commit()   

            paths_query = select([paths.c['path_id']])
            query_result = conn.execute(paths_query)
            existing_paths = [row[0] for row in query_result]

        if f'{source},{target}' in existing_paths:
            with engine.connect() as conn:
                update_query = (
                    update(requests)
                    .where(requests.c.request_id == request_id)
                    .values(
                        status='COMPLETE',
                        path_id=f'{source},{target}'
                        )
                )
                conn.execute(update_query)
                conn.commit()   
        else:
            logger.exception(get_next_squares())
            # result = find_knights_path(
            #     source, 
            #     target, 
            #     engine, 
            #     paths, 
            #     existing_paths
            #     )

    return {
        'statusCode': 200,
        'body': f"Request complete"
    }