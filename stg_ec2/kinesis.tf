resource "aws_kinesis_stream" "stream" {
  name             = "${var.name}-kinesis"
  shard_count      = 1
  retention_period = 48

  shard_level_metrics = [
    "IncomingBytes",
    "OutgoingBytes",
  ]

  tags = {
    "Environment" = "${var.name}-kinesis"
  }
}

resource "aws_s3_bucket" "kinesis-log" {
  bucket = "${var.name}-kinesis-log"
  versioning {
    enabled = true
  }
  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }
}
