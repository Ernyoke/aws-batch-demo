variable "aws_region" {
  default = "us-east-1"
}

variable "module_name" {
  default = "movies-load-batch"
}

variable "table_name" {
  default = "movies"
}

variable "bucket" {
  default = "my-bucket-01234"
}

variable "file_path" {
  default = "archive.zip"
}