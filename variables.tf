variable "env" {}

variable "subnets" {
  type        = "list"
  description = "List of VPC Subnets IDs used to do lambdas"
}

variable "rds_sg" {
  type        = "list"
  description = "List of Security Groups ID's to use for consulRdsCreateService lambda"
}

variable "rds_vpc_ids" {
  type        = "list"
  default     = []
  description = "List of VPC ID's the consulRdsCreateService lambda will attempt to discover RDS instances in. Defaults empty array"
}
