# Creating VPC
resource "aws_vpc" "eks_vpc" {
  cidr_block           = var.vpc_cidr
  instance_tenancy     = "default"
  enable_dns_hostnames = true

  tags = {
    Name = "${var.project_name}-vpc"
    Env  = var.env
    Type = var.type
  }
}

# Creating Internet Gateway and attach it to VPC
resource "aws_internet_gateway" "eks_internet_gateway" {
  vpc_id = aws_vpc.eks_vpc.id

  tags = {
    Name = "${var.project_name}-igw"
    Env  = var.env
    Type = var.type
  }
}

# Using data source to get all Avalablility Zones in region
data "aws_availability_zones" "available_zones" {}

# Creating Public Subnet AZ1
resource "aws_subnet" "public_subnet_az1" {
  vpc_id                  = aws_vpc.eks_vpc.id
  cidr_block              = var.public_subnet_az1_cidr
  availability_zone       = data.aws_availability_zones.available_zones.names[0]
  map_public_ip_on_launch = true

  tags = {
    Name = "Public Subnet AZ1"
    Env  = var.env
    Type = var.type
  }
}

# Creating Public Subnet AZ2
resource "aws_subnet" "public_subnet_az2" {
  vpc_id                  = aws_vpc.eks_vpc.id
  cidr_block              = var.public_subnet_az2_cidr
  availability_zone       = data.aws_availability_zones.available_zones.names[1]
  map_public_ip_on_launch = true

  tags = {
    Name = "Public Subnet AZ2"
    Env  = var.env
    Type = var.type
  }
}

# Creating Route Table and add Public Route
resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.eks_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.eks_internet_gateway.id
  }

  tags = {
    Name = "Public Route Table"
    Env  = var.env
    Type = var.type
  }
}

# Associating Public Subnet in AZ1 to route table
resource "aws_route_table_association" "public_subnet_az1_route_table_association" {
  subnet_id      = aws_subnet.public_subnet_az1.id
  route_table_id = aws_route_table.public_route_table.id
}

# Associating Public Subnet in AZ2 to route table
resource "aws_route_table_association" "public_subnet_az2_route_table_association" {
  subnet_id      = aws_subnet.public_subnet_az2.id
  route_table_id = aws_route_table.public_route_table.id
}
## private subnet task ///
# Creating Private Subnet AZ1
resource "aws_subnet" "private_subnet_az1" {
  vpc_id                  = aws_vpc.eks_vpc.id
  cidr_block              = var.private_subnet_az1_cidr
  availability_zone       = data.aws_availability_zones.available_zones.names[0]
  map_public_ip_on_launch = true

  tags = {
    Name = "private Subnet AZ1"
    Env  = var.env
    Type = var.type
  }
}

# Creating private Subnet AZ2
resource "aws_subnet" "private_subnet_az2" {
  vpc_id                  = aws_vpc.eks_vpc.id
  cidr_block              = var.private_subnet_az2_cidr
  availability_zone       = data.aws_availability_zones.available_zones.names[1]
  map_public_ip_on_launch = true

  tags = {
    Name = "private Subnet AZ2"
    Env  = var.env
    Type = var.type
  }
}


# Creating Route Table and add private Route
resource "aws_route_table" "private_route_table_az1" {
  vpc_id = aws_vpc.eks_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_gw_az1.id
  }

  tags = {
    Name = "private Route Table"
    Env  = var.env
    Type = var.type
  }
}


# Associating  private Subnet in AZ1 to route table
resource "aws_route_table_association" "private_subnet_az1_route_table_association" {
  subnet_id      = aws_subnet.private_subnet_az1.id
  route_table_id = aws_route_table.private_route_table_az1.id
}


# Associating private Subnet in AZ2 to route table
resource "aws_route_table_association" "private_subnet_az2_route_table_association" {
  subnet_id      = aws_subnet.private_subnet_az2.id
  route_table_id = aws_route_table.private_route_table_az2.id
}

# NAT Gateways for high availability
resource "aws_eip" "nat_eip_az1" {
  vpc = true
}



resource "aws_nat_gateway" "nat_gw_az1" {
  allocation_id = aws_eip.nat_eip_az1.id
  subnet_id     = aws_subnet.public_subnet_az1.id

  tags = {
    Name = "NATGatewayAZ1"
  }
}


resource "aws_eip" "nat_eip_az2" {
  vpc = true
}

resource "aws_nat_gateway" "nat_gw_az2" {
  allocation_id = aws_eip.nat_eip_az2.id
  subnet_id     = aws_subnet.public_subnet_az2.id

  tags = {
    Name = "NATGatewayAZ2"
  }
}


# Route Table for private subnet in AZ2
resource "aws_route_table" "private_route_table_az2" {
  vpc_id = aws_vpc.eks_vpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_gw_az2.id
  }

  tags = {
    Name = "PrivateRouteTableAZ2"
  }
}


# Network ACL
resource "aws_network_acl" "main_network_acl" {
  vpc_id = aws_vpc.eks_vpc.id

  # Inbound rules allowing HTTP, HTTPS, and EKS communication
  ingress {
    protocol   = "-1" # -1 for all protocols
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }

  # Outbound rules allowing all traffic
  egress {
    protocol   = "-1" # -1 for all protocols
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }
  tags = {
    Name = "MainNetworkACL"
  }
}

resource "aws_network_acl" "main_network_acl_privateA" {
  vpc_id = aws_vpc.eks_vpc.id

  # Inbound rules - Allow all traffic
  ingress {
    protocol   = "-1" # All protocols
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0" # Allow from all IPs
    from_port  = 0
    to_port    = 0
  }

  # Outbound rules - Allow all traffic
  egress {
    protocol   = "-1" # All protocols
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0" # Allow to all IPs
    from_port  = 0
    to_port    = 0
  }

  tags = {
    Name = "MainNetworkACLPrivateA"
  }
}

resource "aws_network_acl" "main_network_acl_privateB" {
   vpc_id = aws_vpc.eks_vpc.id
#    # Inbound rules - Allow all traffic

# Inbound rules - Allow all traffic
  ingress {
    protocol   = "-1" # All protocols
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0" # Allow from all IPs
    from_port  = 0
    to_port    = 0
  }

  # Outbound rules - Allow all traffic
  egress {
    protocol   = "-1" # All protocols
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0" # Allow to all IPs
    from_port  = 0
    to_port    = 0
  }


#  # Outbound rules - Allow all traffic
#  egress {
#    protocol   = "-1" # All protocols
#    rule_no    = 100
#    action     = "allow"
#    cidr_block = var.private_subnet_az1_cidr
#    from_port  = 0
#    to_port    = 0
#  }
#    # Outbound rules - Allow all traffic
#  egress {
#    protocol   = "-1" # All protocols
#    rule_no    = 110
#    action     = "allow"
#    cidr_block = var.private_subnet_az2_cidr
#    from_port  = 0
#    to_port    = 0
#  }
#    # Outbound rules - Allow all traffic
#  egress {
#    protocol   = "-1" # All protocols
#    rule_no    = 120
#    action     = "allow"
#    cidr_block = var.private_2_subnet_az1_cidr
#    from_port  = 0
#    to_port    = 0
#  }
#    # Outbound rules - Allow all traffic
#  egress {
#    protocol   = "-1" # All protocols
#    rule_no    = 130
#    action     = "allow"
#    cidr_block = var.private_2_subnet_az2_cidr
#    from_port  = 0
#    to_port    = 0
#  }
#  # Outbound rules - Allow all traffi
#
   tags = {
     Name = "MainNetworkACLPrivateB"
   }
}


# Associate subnets with Network ACL
resource "aws_network_acl_association" "private_subnet_az1_association" {
  network_acl_id = aws_network_acl.main_network_acl_privateA.id
  subnet_id      = aws_subnet.private_subnet_az1.id
}

resource "aws_network_acl_association" "private_subnet_az2_association" {
  network_acl_id = aws_network_acl.main_network_acl_privateB.id
  subnet_id      = aws_subnet.private_subnet_az2.id
}

resource "aws_network_acl_association" "private_subnet_az3_association" {
  network_acl_id = aws_network_acl.main_network_acl.id
  subnet_id      = aws_subnet.private_subnet_az3.id
}

resource "aws_network_acl_association" "private_subnet_az4_association" {
  network_acl_id = aws_network_acl.main_network_acl.id
  subnet_id      = aws_subnet.private_subnet_az4.id
}

##private subnet 3----------------
## private subnet task ///
# Creating Private Subnet AZ1
resource "aws_subnet" "private_subnet_az3" {
  vpc_id                  = aws_vpc.eks_vpc.id
  cidr_block              = var.private_2_subnet_az1_cidr
  availability_zone       = data.aws_availability_zones.available_zones.names[0]
  map_public_ip_on_launch = true

  tags = {
    Name = "private Subnet private_subnet_az3"
    Env  = var.env
    Type = var.type
  }
}

## Creating private Subnet AZ2
resource "aws_subnet" "private_subnet_az4" {
  vpc_id                  = aws_vpc.eks_vpc.id
  cidr_block              = var.private_2_subnet_az2_cidr
  availability_zone       = data.aws_availability_zones.available_zones.names[1]
  map_public_ip_on_launch = true

  tags = {
    Name = "private Subnet private_subnet_az4"
    Env  = var.env
    Type = var.type
  }
}


# Creating Route Table and add private Route
resource "aws_route_table" "private_route_table_az3" {
  vpc_id = aws_vpc.eks_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_gw_az1.id
  }

  tags = {
    Name = "private 2 Route Table 1"
    Env  = var.env
    Type = var.type
  }
}
# Route Table for private subnet in AZ2
resource "aws_route_table" "private_route_table_az4" {
  vpc_id = aws_vpc.eks_vpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_gw_az2.id
  }

  tags = {
    Name = "PrivateRouteTableAZ24"
  }
}


# Associating  private Subnet in AZ1 to route table
resource "aws_route_table_association" "private_subnet_az3_route_table_association" {
  subnet_id      = aws_subnet.private_subnet_az3.id
  route_table_id = aws_route_table.private_route_table_az3.id
}


# Associating private Subnet in AZ2 to route table
resource "aws_route_table_association" "private_subnet_az4_route_table_association" {
  subnet_id      = aws_subnet.private_subnet_az4.id
  route_table_id = aws_route_table.private_route_table_az4.id
}

## NAT Gateways for high availability
#resource "aws_eip" "nat_eip_az3" {
#  vpc = true
#}
#
#
#
#resource "aws_nat_gateway" "nat_gw_az3" {
#  allocation_id = aws_eip.nat_eip_az3.id
#  subnet_id     = aws_subnet.public_subnet_az1.id
#
#  tags = {
#    Name = "NATGatewayAZ21"
#  }
#}
#
#
#resource "aws_eip" "nat_eip_az4" {
#  vpc = true
#}
#
#resource "aws_nat_gateway" "nat_gw_az4" {
#  allocation_id = aws_eip.nat_eip_az4.id
#  subnet_id     = aws_subnet.public_subnet_az2.id
#
#  tags = {
#    Name = "NATGatewayAZ22"
#  }
#}
#
#

