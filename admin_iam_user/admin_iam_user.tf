variable "pgp_key" {}

resource "aws_iam_user" "admin-user" {
  name = "admin-user"
  path = "/"
  # IAMユーザーを削除じにログインプロファイルやアクセスキーも削除
  force_destroy =true
}

# jsonの読み込み、変数化
resource "aws_iam_policy" "admin-policy" {
  name =  "AdministerPolicy"
  policy = file("./admin_policy.json")
}

# 実際にiamユーザーにアタッチ
resource "aws_iam_user_policy_attachment" "admin-attach" {
  user = aws_iam_user.admin-user.name
  policy_arn = aws_iam_policy.admin-policy.arn
}

# webコンソールログイン時のログイン情報
resource "aws_iam_user_login_profile" "admin-user-login-profile" {
  user = aws_iam_user.admin-user.name
  pgp_key = var.pgp_key
  password_reset_required = false
}

#  AWS_CLIやAPIを利用する際の認証情報
resource "aws_iam_access_key" "admin-user-access-key" {
  user = aws_iam_user.admin-user.name
  pgp_key = var.pgp_key
}

output "admin_user_iam_access_key" {
    value = aws_iam_access_key.admin-user-access-key.id
}

output "admin_user_iam_enrypted_secret" {
    value = aws_iam_access_key.admin-user-access-key.encrypted_secret
}
