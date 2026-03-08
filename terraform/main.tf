module "ecs" {
  source = "./ecs_module"

  # Cluster & service — environment is embedded in the name
  cluster_name = "${var.environment}-${var.cluster_name}"
  service_name = "${var.environment}-${var.service_name}"

  # Task sizing
  task_cpu    = var.task_cpu
  task_memory = var.task_memory

  # Container
  container_image = var.container_image
  container_name  = var.container_name
  container_port  = var.container_port

  # Scaling
  desired_count = var.desired_count

    # Environment variables — merge user-provided with auto-injected APP_ENV
  environment_variables = merge(var.environment_variables, { APP_ENV = var.environment })

  # Networking (mocked values are fine for terraform plan)
  subnets          = var.subnets
  security_groups  = var.security_groups
  assign_public_ip = var.assign_public_ip

  # Logging
  aws_region         = var.aws_region
  log_retention_days = var.log_retention_days
}
