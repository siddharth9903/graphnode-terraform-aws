output "rds_endpoint" {
  description = "The endpoint of the RDS cluster"
  value       = aws_rds_cluster.graphnode.endpoint
}

output "rds_port" {
  description = "The port of the RDS cluster"
  value       = aws_rds_cluster.graphnode.port
}

output "rds_security_group_id" {
  description = "The ID of the RDS security group"
  value       = aws_security_group.rds.id
}