output "ecs_instance_id" {
  value = aws_ecs_service.service.id
}

output "ecr_repo_name" {
  value = module.ecr.name
}
