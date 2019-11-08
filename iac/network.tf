
variable "subnet_ecs_cidr_a" {
    default = "10.1.11.0/24"
}
variable "subnet_ecs_cidr_b" {
    default = "10.1.12.0/24"
}
variable "subnet_lb_cidr_a" {
    default = "10.1.21.0/24"
}
variable "subnet_lb_cidr_b" {
    default = "10.1.22.0/24"
}
variable "subnet_rds_a" {
    default = "10.1.31.0/24"
}
variable "subnet_rds_b" {
    default = "10.1.32.0/24"
}
variable "subnet_natgw" {
    default = "10.1.41.0/24"
}
variable "vpc_cidr" {
    default = "10.1.0.0/16"
}

# VPC
resource "aws_vpc" "notejam" {
  cidr_block            = "${var.vpc_cidr}"
  instance_tenancy      = "default"
  enable_dns_hostnames  = true
  
  tags = {
      Name = "${var.proj_name}-${terraform.workspace}"
  }
}

# Internet gateway
# to be used in RTB for public subnets
resource "aws_internet_gateway" "igw" {
  vpc_id = "${aws_vpc.notejam.id}"
  tags = {
      Name = "${var.proj_name}-${terraform.workspace}-igw"
  }
}

# Elastic IPs
resource "aws_eip" "eip" {
  vpc = true
}

# NAT Gateways
# to be used in RTB for private subnets where internet access is needed 
resource "aws_nat_gateway" "natgw" {
  subnet_id     = "${aws_subnet.natgw.id}"
  allocation_id = "${aws_eip.eip.id}"
}

# ECS SUBNETS
resource "aws_subnet" "ecs_a" {
  availability_zone = "${var.region}a"
  cidr_block        = "${var.subnet_ecs_cidr_a}"
  vpc_id            = "${aws_vpc.notejam.id}"
  tags = {
      Name = "${var.proj_name}-${terraform.workspace}-ecs-a"
  }
}
resource "aws_subnet" "ecs_b" {
  availability_zone = "${var.region}b"
  cidr_block        = "${var.subnet_ecs_cidr_b}"
  vpc_id            = "${aws_vpc.notejam.id}"
  
  tags = {
      Name = "${var.proj_name}-${terraform.workspace}-ecs-b"
  }
}

# LB SUBNETS
resource "aws_subnet" "lb_a" {
  availability_zone = "${var.region}a"
  cidr_block        = "${var.subnet_lb_cidr_a}"
  vpc_id            = "${aws_vpc.notejam.id}"
  
  tags = {
      Name = "${var.proj_name}-${terraform.workspace}-lb-a"
  }
}
resource "aws_subnet" "lb_b" {
  availability_zone = "${var.region}b"
  cidr_block        = "${var.subnet_lb_cidr_b}"
  vpc_id            = "${aws_vpc.notejam.id}"
  
  tags = {
      Name = "${var.proj_name}-${terraform.workspace}-lb-b"
  }
}

# RDS SUBNETS
resource "aws_subnet" "rds_a" {
  availability_zone = "${var.region}a"
  cidr_block        = "${var.subnet_rds_a}"
  vpc_id            = "${aws_vpc.notejam.id}"
  tags = {
      Name = "${var.proj_name}-${terraform.workspace}-rds-a"
  }
}
resource "aws_subnet" "rds_b" {
  availability_zone = "${var.region}b"
  cidr_block        = "${var.subnet_rds_b}"
  vpc_id            = "${aws_vpc.notejam.id}"
  
  tags = {
      Name = "${var.proj_name}-${terraform.workspace}-rds-b"
  }
}

# Nat gateway
resource "aws_subnet" "natgw" {
  availability_zone = "${var.region}b"
  cidr_block        = "${var.subnet_natgw}"
  vpc_id            = "${aws_vpc.notejam.id}"
  
  tags = {
      Name = "${var.proj_name}-${terraform.workspace}-natgw"
  }
}

# PUBLIC ROUTE TABLE
resource "aws_route_table" "public" {
  vpc_id = "${aws_vpc.notejam.id}"

  # default route via igw
  route = {
      cidr_block = "0.0.0.0/0"
      gateway_id = "${aws_internet_gateway.igw.id}"
  }
  tags = {
      Name = "${var.proj_name}-${terraform.workspace}-public"
  }
}

# PRIVATE ROUTE TABLE
resource "aws_route_table" "private" {
  vpc_id = "${aws_vpc.notejam.id}"

  # default route via natgw
  route = {
      cidr_block = "0.0.0.0/0"
      nat_gateway_id = "${aws_nat_gateway.natgw.id}"
  }
  tags = {
      Name = "${var.proj_name}-${terraform.workspace}-private"
  }
}


# SUBNETS and ROUTE TABLE ASSOCIATIONS

# ECS
resource "aws_route_table_association" "ecs_a" {
  subnet_id = "${aws_subnet.ecs_a.id}"
  route_table_id = "${aws_route_table.private.id}"
}
resource "aws_route_table_association" "ecs_b" {
  subnet_id = "${aws_subnet.ecs_b.id}"
  route_table_id = "${aws_route_table.private.id}"
}

# LB
resource "aws_route_table_association" "lb_a" {
  subnet_id = "${aws_subnet.lb_a.id}"
  route_table_id = "${aws_route_table.public.id}"
}
resource "aws_route_table_association" "lb_b" {
  subnet_id = "${aws_subnet.lb_b.id}"
  route_table_id = "${aws_route_table.public.id}"
}

# RDS 
# resource "aws_route_table_association" "rds_a" {
#   subnet_id = "${aws_subnet.rds_a.id}"
#   route_table_id = "${aws_route_table.private.id}"
# }
# resource "aws_route_table_association" "rds_b" {
#   subnet_id = "${aws_subnet.rds_b.id}"
#   route_table_id = "${aws_route_table.private.id}"
# }

# NATGW
resource "aws_route_table_association" "natgw" {
  subnet_id = "${aws_subnet.natgw.id}"
  route_table_id = "${aws_route_table.public.id}"
}

