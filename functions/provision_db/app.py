from sqlalchemy import MetaData, Table, Column, String, ForeignKey, Integer, create_engine
import os

DB_USER = os.getenv('DB_USER')
DB_PASSWORD = os.getenv('DB_PASSWORD')
DB_HOST = os.getenv('DB_HOST')
DB_DATABASE = os.getenv('DB_DATABASE')

def lambda_handler(event, context):
    engine = create_engine(f"postgresql+psycopg2://{DB_USER}:{DB_PASSWORD}@{DB_HOST}/{DB_DATABASE}")

    metadata_obj = MetaData()

    path = Table(
        "path",
        metadata_obj,
        Column("path_id", String(5), primary_key=True),
        Column("starting", String(2), nullable=False),
        Column("ending", String(2), nullable=False),
        Column("number_of_moves", Integer, nullable=False),
        Column("path_desc", String(192), nullable=False)
    )

    request = Table(
        "request",
        metadata_obj,
        Column("request_id", String(36), primary_key=True),
        Column("status", String(16), nullable=False),
        Column("path_id", String(5)),
        Column("message", String(100))
    )
    metadata_obj.create_all(engine)
    # request.drop(engine)
    # path.drop(engine)
    return {
        "statusCode": 200,
        "body": "Successly ran migration"
    }
