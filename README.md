Terraform module to deploy Lambda Functions for Consul
===========

Terraform module to deploy Lambda Functions for Consul


This module

- Deploys a Lambda (consulRdsCreateService) within a VPC which adds RDS instances as Consul Services, the Lambda also populates the KV store with a some relvant data about the Databases.   



----------------------
#### Required
- `env`     - env to deploy in, i.e dev/staging/prod
- `subnets` - List of VPC Subnets IDs used to do lambdas
- `rds_sg`  - List of Security Groups ID's to use for consulRdsCreateService lambda

#### Optional

- `rds_vpc_ids` - List of VPC ID's the consulRdsCreateService lambda will attempt to discover RDS instances in. Defaults empty array

Usage
-----

```hcl
module "consul_lambdas" {
  source      = "../modules/terraform-aws-consul-lambda"
  env         = "${var.env}"
  vpc_id      = "${module.vpc.vpc_id}"
  subnets     = "${module.vpc.private_subnets}"
  rds_sg      = "${list(module.vpc.default_security_group_id)}"
  rds_vpc_ids = "${var.consul_lambdas_rds_vpc_ids}"
}
```

Outputs
=======

Authors
=======

[Tim Hartmann](https://github.com/tfhartmann)

License
=======

[MIT License](LICENSE.md)
