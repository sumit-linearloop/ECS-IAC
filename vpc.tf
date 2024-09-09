
# VPC
resource "aws_vpc" "my_vpc" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "my-vpc"
  }
}


# Subnet
resource "aws_subnet" "subnet_1" {
  vpc_id            = aws_vpc.my_vpc.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "ap-south-1a"
  map_public_ip_on_launch = true


  tags = {
    Name = "my-subnet-1"
  }
}

resource "aws_subnet" "subnet_2" {
  vpc_id            = aws_vpc.my_vpc.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "ap-south-1b"
  map_public_ip_on_launch = true


  tags = {
    Name = "my-subnet-2"
  }
}


# Route Table
resource "aws_route_table" "route_table_1" {
  vpc_id = aws_vpc.my_vpc.id

  tags = {
    Name = "my-route-table-1"
  }
}
 
resource "aws_route_table" "route_table_2" {
  vpc_id = aws_vpc.my_vpc.id

  tags = {
    Name = "my-route-table-2"
  }
}


# Route Table Association
resource "aws_route_table_association" "rta_1" {
  subnet_id      = aws_subnet.subnet_1.id
  route_table_id = aws_route_table.route_table_1.id
}

resource "aws_route_table_association" "rta_2" {
  subnet_id      = aws_subnet.subnet_2.id
  route_table_id = aws_route_table.route_table_2.id
}


# Internet Gateway
resource "aws_internet_gateway" "my_igw" {
  vpc_id = aws_vpc.my_vpc.id

  tags = {
    Name = "my-igw"
  }
}


# Route Table to Attache to Internet Gateway

resource "aws_route" "route_to_igw_1" {
  route_table_id         = aws_route_table.route_table_1.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.my_igw.id
}

# Route to Internet Gateway in Route Table 2
resource "aws_route" "route_to_igw_2" {
  route_table_id         = aws_route_table.route_table_2.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.my_igw.id
}
