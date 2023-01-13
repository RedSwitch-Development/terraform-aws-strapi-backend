variable "account_id" {
  type        = string
  description = "AWS Account Id"
}

variable "region" {
  type        = string
  description = "Name of AWS region"
}

variable "vpc_id" {
  type        = string
  description = "VPC id for Target Group of the application"
}

variable "alb_listener_arn" {
  type        = string
  description = "ARN of the main ALB Listener"
}

variable "service_name" {
  type        = string
  description = "Name of the service that these resources belong to"
}

variable "environment" {
  type        = string
  description = "Application environment this resource will be used for, e.g. development, testing, qa, production"
}

variable "application_url" {
  type        = string
  description = "URL for the application without the scheme/protocol. eg. application.redswitch.dev"
}

variable "ecs_cluster_name" {
  type        = string
  description = "Name of ECS cluster"
}

variable "container_name" {
  type        = string
  description = "Name of ECR Container"
}

variable "container_port" {
  default     = 80
  type        = number
  description = "Default port to be exposed in ECR Container"
}

variable "ecr_image_name" {
  type        = string
  description = "Image name to be used in the task definition creation"
}

variable "instance_count" {
  default     = 1
  type        = number
  description = "Number of ECS instances to create"
}

variable "ecs_launch_type" {
  type        = string
  description = "Valid values: ECS, FARGATE"
}

variable "cpu" {
  type        = number
  description = "Number of CPU units for task definition"
}

variable "memory" {
  type        = number
  description = "Memory allocated for the task definition in MB"
}

variable "task_role_arn" {
  type        = string
  description = "ARN for ECS instance to access other aws services"
}

variable "subnets" {
  type        = list(string)
  description = "List of Subnet ids to be used by application and database"
}

variable "security_group" {
  type        = string
  description = "Security Group to be used by application and database"
}

variable "force_new_deployment" {
  type        = bool
  default     = true
  description = "If true, ecs service will redeploy on every terraform apply"
}

variable "target_group_arn" {
  type        = string
  description = "ARN of Load Balancer Target Group"
}

variable "environment_variables" {
  default = []
  type = list(object({
    name  = string
    value = string
  }))
  description = "Environment variables for the Task Definition service"
}

variable "task_iam_permissions" {
  default = []
  type = list(object({
    Action   = list(string)
    Effect   = string
    Resource = string
  }))
  description = "Permissions statement array for task IAM role"
}

variable "db_engine" {
  type        = string
  description = "Engine for database, e.g. postgres, mysql"
}

variable "db_engine_version" {
  type        = string
  description = "Engine version corresponding to the database engine"
}

variable "db_major_engine_version" {
  type        = string
  description = "Major engine version corresponding to the database engine, this will probably match db_engine_version"
}

variable "db_instance_class" {
  type        = string
  default     = "db.t3.micro"
  description = "AWS instance to host database on. Defaults to cheapest free-tier option"
}

variable "db_allocated_storage" {
  type        = number
  description = "Storage allocated to database in gigabytes"
}

variable "db_name" {
  type        = string
  description = "Name for database"
}

variable "db_username" {
  type        = string
  description = "Admin username for database"
}

variable "db_password" {
  type        = string
  description = "Admin password for database"
}

variable "db_port" {
  type        = string
  description = "Port to expose for database"
}
