# Kinesis stream for ingesting the textual data from
resource "aws_kinesis_stream" "input_stream" {
  name        = var.stream_name
  shard_count = var.shards

  tags = local.common_tags
}

# Checkpoint location for Spark streaming on S3
resource "aws_s3_bucket" "checkpoint" {
  bucket = var.checkpoint_bucket

  force_destroy = true
  tags          = local.common_tags
}
