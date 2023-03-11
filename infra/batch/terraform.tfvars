aws_region  = "us-east-1"
module_name = "movies-load-batch" # Identifier used as a prefix for name each resource
table_name  = "movies"            # DynamoDB Table name
bucket_name = "my-bucket-01234"   # The name of the bucke for the input data
file_path   = "archive.zip"       # The path of the object from the input bucket