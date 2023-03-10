import csv
import io
import os
from zipfile import ZipFile

import boto3


def download_content(bucket, key):
    print(f'Downloading data from bucket {bucket}/{key}!')
    s3 = boto3.resource('s3')
    response = s3.Object(bucket, key).get()
    print('Extracting data!')
    zip_file = ZipFile(io.BytesIO(response['Body'].read()), "r")
    files = {name: zip_file.read(name) for name in zip_file.namelist()}
    return files.get(next(iter(files.keys())))


def write_to_dynamo(csv_content, table_name):
    print('Parsing csv data!')
    reader = csv.DictReader(io.StringIO(bytes.decode(csv_content)))

    dynamo = boto3.resource('dynamodb')
    table = dynamo.Table(table_name)

    print(f'Starting to write data into table {table_name}!')
    counter = 0
    with table.batch_writer() as batch:
        for row in reader:
            counter += 1
            batch.put_item(
                Item={
                    'id': row[''],
                    'title': row['title'],
                    'overview': row['overview'],
                    'release_date': row['release_date'],
                    'vote_average': row['vote_average'],
                    'vote_count': row['vote_count'],
                    'original_language': row['original_language'],
                    'popularity': row['popularity']
                }
            )

            if counter % 100 == 0:
                print(f'Written {counter} items into table {table_name}!')

    print(f'Finished writing data into {table_name}!')


if __name__ == '__main__':
    bucket = os.environ['BUCKET']
    key = os.environ['FILE_PATH']
    table_name = os.environ['TABLE_NAME']

    is_env_missing = False

    if bucket is None:
        print(f'Environment variable BUCKET is not set!')
        is_env_missing = True

    if key is None:
        print(f'Environment variable FILE_PATH is not set!')
        is_env_missing = True

    if table_name is None:
        print(f'Environment variable TABLE_NAME is not set!')
        is_env_missing = True

    if is_env_missing:
        print('Execution finished with one ore more errors!')

    content = download_content(bucket, key)
    write_to_dynamo(content, table_name)
