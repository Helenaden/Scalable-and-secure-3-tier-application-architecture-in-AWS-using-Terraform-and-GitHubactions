# Internet Gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.three_tier_app_vpc.id

  tags = {
    Name = "Internet Gateway"
  }
}

# Public Route Table
resource "aws_route_table" "public-route-table" {
  vpc_id = aws_vpc.three_tier_app_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "Public Route Table"
  }
}

# Public Subnet Route Associations
resource "aws_route_table_association" "public-subnet-1-route-association" {
  subnet_id      = aws_subnet.public-web-subnet-1.id
  route_table_id = aws_route_table.public-route-table.id
}

resource "aws_route_table_association" "public-subnet-2-route-association" {
  subnet_id      = aws_subnet.public-web-subnet-2.id
  route_table_id = aws_route_table.public-route-table.id
}

# EIP for NAT Gateway 1
resource "aws_eip" "nat_gateway_eip_1" {
  tags = {
    Name = "NAT Gateway EIP 1"
  }
}

# EIP for NAT Gateway 2
resource "aws_eip" "nat_gateway_eip_2" {
  tags = {
    Name = "NAT Gateway EIP 2"
  }
}

# NAT Gateway 1
resource "aws_nat_gateway" "nat_gw_1" {
  allocation_id = aws_eip.nat_gateway_eip_1.id
  subnet_id     = aws_subnet.public-web-subnet-1.id

  tags = {
    Name = "NAT Gateway 1"
  }
}

# NAT Gateway 2
resource "aws_nat_gateway" "nat_gw_2" {
  allocation_id = aws_eip.nat_gateway_eip_2.id
  subnet_id     = aws_subnet.public-web-subnet-2.id

  tags = {
    Name = "NAT Gateway 2"
  }
}

# Private Route Table for App & DB Subnet 1
resource "aws_route_table" "private-route-table-1" {
  vpc_id = aws_vpc.three_tier_app_vpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_gw_1.id
  }
  tags = {
    Name = "Private Route Table 1"
  }
}

# Private Route Table for App & DB Subnet 2
resource "aws_route_table" "private-route-table-2" {
  vpc_id = aws_vpc.three_tier_app_vpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_gw_2.id
  }

  tags = {
    Name = "Private Route Table 2"
  }
}

# Private App Subnet Route Associations
resource "aws_route_table_association" "private_app_subnet_1_assoc" {
  subnet_id      = aws_subnet.private-app-subnet-1.id
  route_table_id = aws_route_table.private-route-table-1.id
}

resource "aws_route_table_association" "private_app_subnet_2_assoc" {
  subnet_id      = aws_subnet.private-app-subnet-2.id
  route_table_id = aws_route_table.private-route-table-2.id
}

# Private DB Subnet Route Associations
resource "aws_route_table_association" "private_db_subnet_1_assoc" {
  subnet_id      = aws_subnet.private-db-subnet-1.id
  route_table_id = aws_route_table.private-route-table-1.id
}

resource "aws_route_table_association" "private_db_subnet_2_assoc" {
  subnet_id      = aws_subnet.private-db-subnet-2.id
  route_table_id = aws_route_table.private-route-table-2.id
}