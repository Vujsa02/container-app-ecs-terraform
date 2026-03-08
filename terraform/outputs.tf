output "cluster_name" {
  description = "ECS cluster name"
  value       = module.ecs.cluster_name
}

output "cluster_arn" {
  description = "ECS cluster ARN"
  value       = module.ecs.cluster_arn
}

output "service_name" {
  description = "ECS service name"
  value       = module.ecs.service_name
}

output "service_arn" {
  description = "ECS service ARN"
  value       = module.ecs.service_arn
}

output "task_definition_arn" {
  description = "Current task definition revision ARN"
  value       = module.ecs.task_definition_arn
}

output "log_group_name" {
  description = "CloudWatch log group name"
  value       = module.ecs.log_group_name
}
