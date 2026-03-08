variable "cluster_name" {
  description = "Name of the ECS cluster"
  type        = string
}

variable "service_name" {
  description = "Name of the ECS service"
  type        = string
}

variable "desired_count" {
  description = "Number of task instances to run"
  type        = number
  default     = 1

  validation {
    condition     = var.desired_count >= 0
    error_message = "desired_count must be non-negative."
  }
}

variable "task_cpu" {
  description = "CPU units for the Fargate task (256, 512, 1024, 2048, 4096)"
  type        = number
  default     = 256

  validation {
    condition     = contains([256, 512, 1024, 2048, 4096], var.task_cpu)
    error_message = "task_cpu must be one of: 256, 512, 1024, 2048, 4096."
  }
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
  description = "Name of the container inside the task definition"
  type        = string
}

variable "container_port" {
  description = "Port the container listens on"
  type        = number
  default     = 3000
}

variable "environment_variables" {
  description = "Key-value map of environment variables passed to the container"
  type        = map(string)
  default     = {}
}

variable "subnets" {
  description = "List of subnet IDs for the ECS service"
  type        = list(string)
}

variable "security_groups" {
  description = "List of security group IDs for the ECS service"
  type        = list(string)
}

variable "assign_public_ip" {
  description = "Whether to assign a public IP to Fargate tasks (required for public subnets without NAT)"
  type        = bool
  default     = true
}

variable "aws_region" {
  description = "AWS region - used in CloudWatch log configuration"
  type        = string
  default     = "eu-central-1"
}

variable "log_retention_days" {
  description = "CloudWatch log group retention in days (0 = never expire)"
  type        = number
  default     = 30
}


