# ec2, rds
# resource "aws_s3_bucket" "besides-stg-api-stg-s3" {
#   bucket = "besides-stg-api-stg-s3"
#   acl    = "private"
# }

resource "aws_db_instance" "db" {
  identifier              = "${var.name}-db"
  allocated_storage       = 5
  engine                  = "mysql"
  engine_version          = "5.7"
  instance_class          = var.aws_db_instance_class
  storage_type            = "gp2"
  username                = var.aws_db_username
  password                = var.aws_db_password
  backup_retention_period = 1
  vpc_security_group_ids  = [data.terraform_remote_state.network-common.outputs.aws_security_group_db.id]
  db_subnet_group_name    = data.terraform_remote_state.network-env.outputs.aws_db_subnet_group.name
  # https://github.com/terraform-providers/terraform-provider-aws/issues/4910
  final_snapshot_identifier = "${var.name}-final"

  lifecycle {
    prevent_destroy = false
  }
}

resource "aws_db_parameter_group" "default" {
  name   = "${var.name}-db-stg"
  family = "mysql5.7"

  # パラメータドキュメント
  # https://aws.amazon.com/jp/blogs/news/best-practices-for-configuring-parameters-for-amazon-rds-for-mysql-part-3-parameters-related-to-security-operational-manageability-and-connectivity-timeout/
  # 文字セットイントロデューサーを持たないリテラル、および数値から文字列への変換に使用される文字セット
  parameter {
    name         = "character_set_connection"
    value        = "utf8mb4"
    apply_method = "immediate"
  }

  # デフォルトデータベースで使用される文字セット
  parameter {
    name         = "character_set_database"
    value        = "utf8mb4"
    apply_method = "immediate"
  }

  # ファイルシステムの文字セット
  parameter {
    name         = "character_set_filesystem"
    value        = "utf8mb4"
    apply_method = "immediate"
  }

  # クライアントにクエリ結果を返すために使用する文字セット
  parameter {
    name         = "character_set_results"
    value        = "utf8mb4"
    apply_method = "immediate"
  }

  parameter {
    name         = "character_set_server"
    value        = "utf8mb4"
    apply_method = "immediate"
  }

  parameter {
    name         = "collation_connection"
    value        = "utf8mb4_general_ci"
    apply_method = "immediate"
  }

  parameter {
    name         = "collation_server"
    value        = "utf8mb4_general_ci"
    apply_method = "immediate"
  }

  parameter {
    name         = "time_zone"
    value        = "Asia/Tokyo"
    apply_method = "immediate"
  }
}


resource "aws_instance" "web" {
  ami                         = var.aws_instance_ami
  instance_type               = var.aws_instance_type
  key_name                    = aws_key_pair.auth.id
  vpc_security_group_ids      = [data.terraform_remote_state.network-common.outputs.aws_security_group_app.id]
  subnet_id                   = data.terraform_remote_state.network-env.outputs.aws_subnet_public_web.id
  associate_public_ip_address = "true"

  root_block_device {
    volume_type = "gp2"
    volume_size = "20"
  }

  ebs_block_device {
    device_name = "/dev/sdf"
    volume_type = "gp2"
    volume_size = "100"
  }

  tags = {
    "Name" = "${var.name}-instance"
  }
}

resource "aws_eip" "web" {
  instance = "${aws_instance.web.id}"
  vpc      = true
}

resource "null_resource" "provision_master" {
  triggers = {
    "endpoint" = aws_instance.web.id
  }

  connection {
    type        = "ssh"
    timeout     = "30s"
    agent       = false
    user        = "ec2-user"
    host        = aws_eip.web.public_ip
    private_key = file(var.ssh_private_key_path)
  }

  provisioner "file" {
    source      = "tmp/script.sh"
    destination = "/tmp/script.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/script.sh",
      "/tmp/script.sh args",
    ]
  }

  provisioner "file" {
    source      = "conf/nginx.conf"
    destination = "/tmp/nginx.conf"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo cp /tmp/nginx.conf /etc/nginx/",
    ]
  }
}

# https://www.terraform.io/docs/providers/aws/r/elasticache_cluster.html
# https://cloud-textbook.com/144/
resource "aws_elasticache_cluster" "cluster" {
  cluster_id           = "${var.name}-redis"
  engine               = "redis"
  node_type            = var.elasticache_node_type
  num_cache_nodes      = 1
  parameter_group_name = "default.redis3.2"
  engine_version       = "3.2.10"
  port                 = 6379
  # セキュリティグループも作ったら必ずアタッチすること
  security_group_ids = [data.terraform_remote_state.network-common.outputs.aws_security_group_redis.id]
  # https://github.com/terraform-providers/terraform-provider-aws/issues/1171
  subnet_group_name = data.terraform_remote_state.network-env.outputs.aws_elasticache_subnet_group.name
}


# ec2 instance running redash image
resource "aws_instance" "redash" {
  ami                    = var.redash_ami
  instance_type          = var.redash_instance_type
  vpc_security_group_ids = [data.terraform_remote_state.network-common.outputs.aws_security_group_app.id]
  subnet_id              = data.terraform_remote_state.network-env.outputs.aws_subnet_redash.id

  tags = {
    "Name" = "${var.name}-Redash"
  }
}

output "redash" {
  value = aws_instance.redash
}




output "elastic_ip_of_web" {
  value = aws_eip.web.public_ip
}


output "rds" {
  value = aws_db_instance.db
}


output "ec2" {
  value = aws_instance.web
}


output "rds_endpoint" {
  value = aws_db_instance.db.endpoint
}

output "aws_elasticache_redis" {
  value = aws_elasticache_cluster.cluster
}