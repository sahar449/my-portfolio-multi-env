output "alb_controller_role_name" {
  value = aws_iam_role.lb_controller_role.name
}

output "alb_controller_role_arn" {
  value = aws_iam_role.lb_controller_role.arn
}

output "external_dns_role_name" {
  value = aws_iam_role.external_dns_role.name
}

output "external_dns_role_arn" {
  value = aws_iam_role.external_dns_role.arn
}

output "flask_app_role_arn" {
  value = aws_iam_role.flask_app_role.arn
}
