sre_task_owner = "Mihajlo_Vujisic"
environment    = "dev"

# Cluster & Service (environment is appended automatically)
cluster_name = "decenter-cluster"
service_name = "decenter-service"

# Container 
container_name  = "decenter-app"
container_image = "ghcr.io/vujsa02/container-app-ecs-terraform/app:latest"
container_port  = 3000

# Task sizing 
task_cpu    = 256
task_memory = 512

# Scaling
desired_count = 1

# Additional environment variables (APP_ENV is set automatically)
environment_variables = {}

# ── Networking (mocked — real IDs not required for plan) ──
subnets          = ["subnet-mock-a", "subnet-mock-b"]
security_groups  = ["sg-mock-01"]
assign_public_ip = true

# ── Logging ──
log_retention_days = 30
