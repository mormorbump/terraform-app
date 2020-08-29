resource "aws_iam_group" "rails-app" {
  name = "${var.name}-group"
}

resource "aws_iam_group_policy" "rails-app-policy" {
  name  = "${var.name}-group-policy"
  group = aws_iam_group.rails-app.id

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "NotAction": [
        "iam:*",
        "organizations:*"
      ],
      "Resource": "*"
    }
  ]
}
EOF
}

resource "aws_iam_user" "default" {
  name          = var.name
  path          = "/"
  force_destroy = true
}

resource "aws_iam_access_key" "default" {
  user = aws_iam_user.default.name
}

resource "aws_iam_group_membership" "default" {
  name = "leaptriggerprod-membership"
  users = [
    aws_iam_user.default.id
  ]
  group = aws_iam_group.rails-app.id
}