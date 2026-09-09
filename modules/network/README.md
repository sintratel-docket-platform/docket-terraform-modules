# `network` module

VPC with public and private subnets spread across two availability zones, an EKS requirement.

Includes a single NAT Gateway shared by both zones, a cost decision recorded in ADR-005 of the architecture. If the zone hosting the NAT fails, nodes in the other zone lose internet egress.

## Inputs

| Variable | Type | Required | Purpose |
|---|---|---|---|
| `vpc_cidr` | string | No, `10.0.0.0/16` | VPC range |
| `availability_zones` | list(string) | Yes | Zones the subnets are spread across. Validates that there are at least two |
| `public_subnet_cidrs` | list(string) | Yes | Subnets for the load balancer and the NAT |
| `private_subnet_cidrs` | list(string) | Yes | Subnets for the nodes |
| `cluster_name` | string | Yes | Tags the subnets so the AWS Load Balancer Controller discovers them |
| `single_nat_gateway` | bool | No, `true` | One shared NAT instead of one per zone |

## Outputs

| Output | What it returns | Who consumes it |
|---|---|---|
| `vpc_id` | VPC identifier | The `cluster` module |
| `public_subnet_ids` | Public subnets | The `cluster` module, for the load balancer |
| `private_subnet_ids` | Private subnets | The `cluster` module, for the nodes |
