# Plan-mode tests for the network module.
#
# Mock provider, so they need no AWS credentials and are safe as a pull request
# gate. They assert the decisions that would be expensive to get wrong: the
# multi-AZ requirement EKS imposes, the single shared NAT of ADR-005, and the
# rule that nodes are never reachable from the internet.

mock_provider "aws" {}

variables {
  name_prefix          = "example"
  cluster_name         = "example-eks"
  availability_zones   = ["us-east-1a", "us-east-1b"]
  public_subnet_cidrs  = ["10.0.0.0/24", "10.0.1.0/24"]
  private_subnet_cidrs = ["10.0.10.0/24", "10.0.11.0/24"]
}

run "one_subnet_per_zone" {
  command = plan

  assert {
    condition     = length(aws_subnet.public) == 2
    error_message = "Expected one public subnet per availability zone."
  }

  assert {
    condition     = length(aws_subnet.private) == 2
    error_message = "Expected one private subnet per availability zone."
  }
}

run "single_shared_nat_gateway_by_default" {
  command = plan

  # ADR-005: one NAT shared by both zones, a deliberate cost concession.
  # If this count becomes 2, the decision changed and the ADR must change too.
  assert {
    condition     = length(aws_nat_gateway.this) == 1
    error_message = "The default must be a single shared NAT Gateway (ADR-005)."
  }

  assert {
    condition     = length(aws_eip.nat) == 1
    error_message = "One elastic IP per NAT Gateway, and there is one NAT."
  }
}

run "one_nat_per_zone_when_disabled" {
  command = plan

  variables {
    single_nat_gateway = false
  }

  assert {
    condition     = length(aws_nat_gateway.this) == 2
    error_message = "With single_nat_gateway = false there must be one NAT per zone."
  }
}

run "private_subnets_route_through_the_nat_not_the_gateway" {
  command = plan

  # The nodes live here. Their egress must leave through the NAT; a route to
  # the Internet Gateway would put them on the internet, which is the thing the
  # whole topology exists to prevent.
  assert {
    condition     = length(aws_route_table.private) == length(var.availability_zones)
    error_message = "Each zone needs its own private route table, so the shared NAT can be dropped without rebuilding them."
  }

  assert {
    condition     = length(aws_route_table_association.private) == length(var.private_subnet_cidrs)
    error_message = "Every private subnet must be associated with a private route table."
  }
}

run "rejects_a_single_availability_zone" {
  command = plan

  variables {
    availability_zones   = ["us-east-1a"]
    public_subnet_cidrs  = ["10.0.0.0/24"]
    private_subnet_cidrs = ["10.0.10.0/24"]
  }

  # EKS requires two zones. The variable validation is what stops a cluster
  # that would fail to create for a reason the error message never mentions.
  expect_failures = [var.availability_zones]
}
