# route53, alb, acm
# resource "aws_route53_zone" "primary" {
#   name = "${var.aws_web_domain}"
# }

# httpの場合はこれで
# resource "aws_route53_record" "www" {
#   zone_id = "${aws_route53_zone.primary.zone_id}"
#   name    = "${var.aws_web_domain}"
#   type    = "A"
#   ttl     = "300"
#   records = ["${aws_eip.web.public_ip}"]
# }

# resource "aws_route53_zone" "staging" {
#   name = "${var.aws_web_domain}"

#   tags = {
#     Environment = "staging"
#   }
# }

# resource "aws_route53_record" "A" {
#   zone_id = "${aws_route53_zone.primary.zone_id}"
#   name    = "${var.aws_web_domain}"
#   type    = "A"
#   # ttl = "300"
#   # records = ["${aws_eip.web.public_ip}"]

#   alias {
#     name                   = "${aws_alb.alb.dns_name}"
#     zone_id                = "${aws_alb.alb.zone_id}"
#     evaluate_target_health = true
#   }
# }

resource "aws_alb" "alb" {
  name = "${var.name}-alb"
  security_groups = [
    data.terraform_remote_state.network-common.outputs.aws_security_group_app.id
  ]
  subnets = [
    data.terraform_remote_state.network-env.outputs.aws_subnet_public_web.id,
    data.terraform_remote_state.network-env.outputs.aws_subnet_public_https.id
  ]
  internal                   = false
  enable_deletion_protection = false
}

# ALBとターゲットグループの設定
resource "aws_alb_target_group" "alb" {
  name     = "${var.name}-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = data.terraform_remote_state.network-common.outputs.aws_vpc.id

  health_check {
    interval            = 300
    path                = "/health_check"
    port                = 80
    protocol            = "HTTP"
    timeout             = 5
    unhealthy_threshold = 2
    matcher             = 200
  }
}

# EC2インスタンスとALBターゲットグループの紐付け
resource "aws_lb_target_group_attachment" "alb" {
  target_group_arn = aws_alb_target_group.alb.arn
  target_id        = aws_instance.web.id
  port             = 80
}

# http
resource "aws_alb_listener" "alb_http_listener" {
  load_balancer_arn = aws_alb.alb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    target_group_arn = aws_alb_target_group.alb.arn
    type             = "forward"
  }
}

# ALB Listener Rule
# https://www.terraform.io/docs/providers/aws/r/lb_listener_rule.html
resource "aws_lb_listener_rule" "http_to_https" {
  listener_arn = "${aws_alb_listener.alb_http_listener.arn}"

  priority = 99

  action {
    type = "redirect"

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }

  condition {
    host_header {
      values = [var.aws_web_subdomain]
    }
  }
}
# https
# https://dev.classmethod.jp/articles/acm-cert-by-terraform/
# resource "aws_alb_listener" "alb_https_listener" {
#   load_balancer_arn = "${aws_alb.alb.arn}"
#   port              = "443"
#   protocol          = "HTTPS"
#   # ssl_policy        = "ELBSecurityPolicy-2015-05"
#   # certificate_arn   = "${aws_acm_certificate.cert.arn}"

#   default_action {
#     target_group_arn = "${aws_alb_target_group.alb.arn}"
#     type             = "forward"
#   }
# }

# resource "aws_elb" "elb" {
#   name    = "${var.name}"

#   security_groups = ["${aws_security_group.app.id}"]

#   listener {
#     instance_port     = 80
#     instance_protocol = "http"
#     lb_port           = 80
#     lb_protocol       = "http"
#   }

# listener {
#   instance_port     = 80
#   instance_protocol = "http"
#   lb_port           = 443
#   lb_protocol       = "https"
#   # ssl_certificate_id = "${aws_acm_certificate.cert.arn}"
# }

#   health_check {
#     healthy_threshold   = 2
#     unhealthy_threshold = 2
#     timeout             = 3
#     target              = "HTTP:80/"
#     interval            = 300
#   }

#   instances                   = ["${aws_instance.web.id}"]
# }


# resource "aws_acm_certificate" "cert" {
#   domain_name               = "${var.aws_web_domain}"
#   validation_method         = "DNS"
# }

# resource aws_route53_record cert_validation {
#   zone_id = aws_route53_zone.staging.zone_id
#   name    = aws_acm_certificate.cert.domain_validation_options[0].resource_record_name
#   type    = aws_acm_certificate.cert.domain_validation_options[0].resource_record_type
#   records = [aws_acm_certificate.cert.domain_validation_options[0].resource_record_value]
#   ttl     = 60
# }

# resource aws_acm_certificate_validation cert {
#   certificate_arn = aws_acm_certificate.cert.arn
#   validation_record_fqdns = [aws_route53_record.cert_validation.fqdn]
# }