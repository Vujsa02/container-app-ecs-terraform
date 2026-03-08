# Terraform - ECS Fargate Module

ECS Fargate module that creates a cluster, task definition, service, IAM execution role, and CloudWatch log group. Designed to pass `terraform plan` locally without real AWS credentials.

## How to run

```bash
cd terraform
terraform init
terraform plan -var-file=environments/dev.tfvars
```

To add another environment, create `environments/qa.tfvars` or `environments/prod.tfvars` with different values and run plan against that file.

## What it creates

- **ECS Cluster** - named `{environment}-{cluster_name}` (e.g. `dev-decenter-cluster`).
- **Task Definition** - runs a single Fargate container with configurable image, CPU, memory, port, and environment variables. Logs go to CloudWatch.
- **ECS Service** - runs `desired_count` tasks on Fargate with configurable networking.
- **IAM Execution Role** - lets the ECS agent pull images and push logs. This is the execution role (used by ECS itself), not a task role (used by the app). The app doesn't call any AWS services, so no task role is needed.
- **CloudWatch Log Group** - named `/ecs/{cluster_name}/{service_name}`, with 30-day retention by default. CloudWatch keeps logs forever if unset, which gets expensive.

## Design decisions

### What's hardcoded and why

- **`launch_type = "FARGATE"`** - this module is Fargate-only. Supporting EC2 would need instance types, AMIs, and auto-scaling groups, changing the module's scope entirely.
- **`network_mode = "awsvpc"`** - the only mode Fargate supports. Exposing it as a variable would just invite invalid configs.
- **`requires_compatibilities = ["FARGATE"]`** - same thing, architectural constant.
- **`logDriver = "awslogs"`** - CloudWatch is the native log destination for ECS. Alternatives like Firelens would need sidecar containers.
- **IAM trust policy for `ecs-tasks.amazonaws.com`** - fixed contract between ECS and IAM. Never changes.
- **`essential = true`** - single-container task, so the container must be essential.

### Environment-aware naming

The root module prepends `var.environment` to cluster and service names. So with `environment = "dev"` and `cluster_name = "decenter-cluster"`, the actual cluster is named `dev-decenter-cluster`. This makes it safe to run multiple environments in the same AWS account without name collisions.

### Environment variables as a generic map

Instead of a dedicated `app_env` variable, the module accepts `environment_variables` as a `map(string)`. Adding new env vars like `DATABASE_URL` or `LOG_LEVEL` is just a tfvars change - no module code needs to change. `APP_ENV` is automatically injected from `var.environment` via `merge()` in the root module, so it always matches the environment name.

### Tags via `default_tags`

The `SRE_TASK` and `Environment` tags are set in the provider's `default_tags` block. This automatically applies them to every AWS resource without passing a tags map through the module. The module itself has no knowledge of tag keys - keeps it reusable.

### Mocked networking

Subnets and security groups are passed as plain string variables. For `terraform plan` these are just mock values (`subnet-mock-a`, `sg-mock-01`). Terraform doesn't validate whether they exist until `apply`. No actual `aws_subnet` or `aws_security_group` resources need to be created.

### IAM - why the managed policy is fine

`AmazonECSTaskExecutionRolePolicy` includes ECR pull permissions, which are technically unused since the image is on GHCR (not ECR). This is acceptable - the extra grants are scoped to ECR and don't introduce privilege escalation. Building a custom policy to remove them would add maintenance for no real security benefit.

### CPU/memory as numbers with `tostring()`

AWS expects `cpu` and `memory` as strings in the task definition API. The module defines them as `number` (so Terraform validation works), then converts with `tostring()`. The `task_cpu` variable validates against the allowed Fargate values (256, 512, 1024, 2048, 4096).

### Log group naming

The log group name is derived from cluster and service name: `/ecs/{cluster}/{service}`. Predictable, easy to find in the CloudWatch console, no separate naming variable needed.

## Outputs

The module outputs cluster name and service name (required by the task), plus ARNs for cluster, service, task definition, log group, and execution role. ARNs are included because they're what you actually reference in IAM policies, event rules, and other Terraform modules - names alone aren't enough.

## Things not implemented

- **No load balancer** - Fargate tasks get an IP but it changes on every restart. A real deployment would need an ALB for a stable endpoint with health checks and TLS termination.
- **No auto-scaling** - `desired_count` is static. Production would add target tracking policies to scale on CPU or request count.
- **No CPU/memory cross-validation** - AWS only allows specific CPU-memory pairs (e.g. 256 CPU limits memory to 512–2048 MiB). The module validates CPU but doesn't cross-check the combination. Could be added with a lookup table.
- **No task role** - if the app ever needs to call AWS services (S3, DynamoDB), a separate IAM role for the task would be needed. Currently the app just serves HTTP so it's unnecessary.
