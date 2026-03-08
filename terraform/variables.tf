variable "aws_region" {
  description = "AWS region for the provider and CloudWatch logs"
  type        = string
  default     = "eu-central-1"
}

variable "sre_task_owner" {
  description = "Value for the SRE_TASK tag"
  type        = string
}

variable "environment" {
  description = "Environment name (e.g. dev, qa, prod)"
  type        = string
}

variable "cluster_name" {
  description = "Name of the ECS cluster"
  type        = string
}

variable "service_name" {
  description = "Name of the ECS service"
  type        = string
}

variable "task_cpu" {
  description = "CPU units for the Fargate task"
  type        = number
  default     = 256
}

variable "task_memory" {
  description = "Memory (MiB) for the Fargate task"
  type        = number
  default     = 512
}

variable "container_image" {
  description = "Docker image URI"
  type        = string
}

variable "container_name" {
  description = "Name of the container in the task definition"
  type        = string
}

variable "container_port" {
  description = "Port the container listens on"
  type        = number
  default     = 3000
}

variable "desired_count" {
  description = "Number of running task instances"
  type        = number
  default     = 1
}

variable "environment_variables" {
  description = "Environment variables passed to the container (key-value map)"
  type        = map(string)
  default     = {}
}

variable "subnets" {
  description = "Subnet IDs for the ECS service (can be mocked for plan)"
  type        = list(string)
}

variable "security_groups" {
  description = "Security group IDs for the ECS service (can be mocked for plan)"
  type        = list(string)
}

variable "assign_public_ip" {
  description = "Assign public IP to Fargate tasks"
  type        = bool
  default     = true
}

variable "log_retention_days" {
  description = "CloudWatch log group retention in days"
  type        = number
  default     = 30
}
