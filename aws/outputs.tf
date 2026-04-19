output "public_instances_connection_command" {
  # value       = { for k, v in aws_instance.public_instances : k => v.public_ip }
  value       = join("\n", [ for k, v in aws_instance.public_instances : "${k}: ssh ubuntu@${v.public_ip}" ])
  description = "Use the public IP to connect to the public instance: `ssh ubuntu@<PUBLIC-IP>`"
}

output "private_instance_connection_command" {
  value       = join("\n", [for k, v in aws_instance.private_instances : "${k}: aws ssm start-session --target ${v.id}" ])
  description = <<-EOF
  Use the instance ids with SSM to connect to the private instance: `aws ssm start-session --target <INSTANCE-ID>`
  EOF
}

# See: https://aws.amazon.com/blogs/database/securely-connect-to-an-amazon-rds-or-amazon-ec2-database-instance-remotely-with-your-preferred-gui/
output "rds_port_forwarding_command" {
  value = <<-EOF
  aws ssm start-session \
    --target ${aws_instance.bastion.id} \
    --document-name AWS-StartPortForwardingSessionToRemoteHost \
    --parameters host="${aws_db_instance.db.address}",portNumber="${aws_db_instance.db.port}",localPortNumber="${aws_db_instance.db.port}"
  EOF
}

output "rds_managed_credentials" {
  value = aws_db_instance.db.master_user_secret[0]
}

# See: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/db_instance#attribute-reference
# See the 'Code snippets' method under 'Connectivity & security' tab in 'Aurora and RDS' page.
output "get_rds_credentials_command" {
  value = <<-EOF
  aws secretsmanager get-secret-value \
    --secret-id '${aws_db_instance.db.master_user_secret[0].secret_arn}' \
    --query SecretString \
    --output text
  EOF
}
