# VPC con subredes publicas y privadas repartidas en dos zonas de disponibilidad.
#
# Las subredes llevan etiquetas que EKS y el AWS Load Balancer Controller usan
# para descubrirlas por su cuenta: sin ellas, el controller no sabe donde crear
# el balanceador ni EKS donde colocar los nodos.

locals {
  # Un unico NAT compartido por ambas zonas es una concesion de costo. La
  # contrapartida: si cae la zona del NAT, la otra pierde salida a internet.
  nat_count = var.single_nat_gateway ? 1 : length(var.availability_zones)
}

resource "aws_vpc" "this" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true # EKS lo exige para resolver los endpoints del clúster

  tags = { Name = "docket-efimero-vpc" }
}

resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id

  tags = { Name = "docket-efimero-igw" }
}

resource "aws_subnet" "public" {
  count = length(var.public_subnet_cidrs)

  vpc_id                  = aws_vpc.this.id
  cidr_block              = var.public_subnet_cidrs[count.index]
  availability_zone       = var.availability_zones[count.index]
  map_public_ip_on_launch = true

  tags = {
    Name = "docket-efimero-publica-${var.availability_zones[count.index]}"
    # El AWS Load Balancer Controller busca esta etiqueta para saber donde
    # crear un balanceador de cara a internet.
    "kubernetes.io/role/elb"                    = "1"
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
  }
}

resource "aws_subnet" "private" {
  count = length(var.private_subnet_cidrs)

  vpc_id            = aws_vpc.this.id
  cidr_block        = var.private_subnet_cidrs[count.index]
  availability_zone = var.availability_zones[count.index]

  tags = {
    Name = "docket-efimero-privada-${var.availability_zones[count.index]}"
    # La equivalente para balanceadores internos.
    "kubernetes.io/role/internal-elb"           = "1"
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
  }
}

# La IP elastica y el NAT van juntos en el mismo modulo para que Terraform los
# destruya a la vez. Una IP elastica sin asociar sigue facturando.
resource "aws_eip" "nat" {
  count  = local.nat_count
  domain = "vpc"

  tags = { Name = "docket-efimero-nat-${count.index}" }
}

resource "aws_nat_gateway" "this" {
  count = local.nat_count

  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.public[count.index].id

  tags = { Name = "docket-efimero-nat-${count.index}" }

  depends_on = [aws_internet_gateway.this]
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.this.id
  }

  tags = { Name = "docket-efimero-rt-publica" }
}

resource "aws_route_table_association" "public" {
  count = length(aws_subnet.public)

  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# Una tabla por subred privada, para que cada zona pueda apuntar a su propio NAT
# el dia que se decida dejar de compartirlo.
resource "aws_route_table" "private" {
  count = length(var.private_subnet_cidrs)

  vpc_id = aws_vpc.this.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.this[var.single_nat_gateway ? 0 : count.index].id
  }

  tags = { Name = "docket-efimero-rt-privada-${var.availability_zones[count.index]}" }
}

resource "aws_route_table_association" "private" {
  count = length(aws_subnet.private)

  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private[count.index].id
}

resource "aws_security_group" "alb" {
  name        = "docket-efimero-alb"
  description = "Entrada publica en 80 y 443 hacia el balanceador"
  vpc_id      = aws_vpc.this.id

  tags = { Name = "docket-efimero-alb" }
}

resource "aws_vpc_security_group_ingress_rule" "alb_http" {
  security_group_id = aws_security_group.alb.id
  description       = "HTTP desde internet"
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 80
  to_port           = 80
  ip_protocol       = "tcp"
}

resource "aws_vpc_security_group_ingress_rule" "alb_https" {
  security_group_id = aws_security_group.alb.id
  description       = "HTTPS desde internet"
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 443
  to_port           = 443
  ip_protocol       = "tcp"
}

resource "aws_security_group" "nodes" {
  name        = "docket-efimero-nodos"
  description = "Nodos del cluster: entrada solo desde el balanceador y entre ellos"
  vpc_id      = aws_vpc.this.id

  tags = { Name = "docket-efimero-nodos" }
}

# Modo ip del AWS Load Balancer Controller: el trafico llega al puerto del
# contenedor, no a un NodePort. Ver CONVENCIONES.md.
resource "aws_vpc_security_group_ingress_rule" "nodes_from_alb" {
  security_group_id            = aws_security_group.nodes.id
  description                  = "Trafico del balanceador hacia los pods"
  referenced_security_group_id = aws_security_group.alb.id
  ip_protocol                  = "-1"
}

resource "aws_vpc_security_group_ingress_rule" "nodes_from_nodes" {
  security_group_id            = aws_security_group.nodes.id
  description                  = "Trafico entre nodos del cluster"
  referenced_security_group_id = aws_security_group.nodes.id
  ip_protocol                  = "-1"
}

resource "aws_vpc_security_group_egress_rule" "alb_all" {
  security_group_id = aws_security_group.alb.id
  description       = "Salida del balanceador"
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}

resource "aws_vpc_security_group_egress_rule" "nodes_all" {
  security_group_id = aws_security_group.nodes.id
  description       = "Salida de los nodos, necesaria para ECR, EKS y SSM"
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}
