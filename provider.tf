provider "aws"{
}
resource "aws_vpc" "test-vpc" {
  cidr_block = "10.0.0.0/16"
}
resource "aws_subnet" "public-subnet" {
  vpc_id     = aws_vpc.test-vpc.id
  cidr_block = "10.0.0.0/24"
 
  tags = {
    Name = "public-subnet"
  }
}
resource "aws_subnet" "private-subnet" {
  vpc_id     = aws_vpc.test-vpc.id
  cidr_block = "10.0.1.0/24"
 
  tags = {
    Name = "private-subnet"
  }
}
 
resource "aws_security_group" "test_access" {
        name = "web_access"
        description = "allow ssh and http"
        vpc_id = aws_vpc.test-vpc.id
 
        ingress {
                from_port = 80
                to_port = 80
                protocol = "tcp"
                cidr_blocks = ["0.0.0.0/0"]
        }
 
        ingress {
                from_port = 22
                to_port = 22
                protocol = "tcp"
                cidr_blocks = ["0.0.0.0/0"]
        }
 
        egress {
                from_port = 0
                to_port = 0
                protocol = "-1"
                cidr_blocks = ["0.0.0.0/0"]
        }
 
 
}
resource "aws_internet_gateway" "test-igw" {
  vpc_id = aws_vpc.test-vpc.id
 
  tags = {
    Name = "test-igw"
  }
}
 
resource "aws_route_table" "public-route" {
  vpc_id = aws_vpc.test-vpc.id
 
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.test-igw.id
  }
 
  tags = {
    Name = "public-route"
  }
}
 
resource "aws_route_table_association" "public-assoc" {
  subnet_id      = aws_subnet.public-subnet.id
  route_table_id = aws_route_table.public-route.id
}
resource "aws_key_pair" "my-key" {
  key_name   = "my-key"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQD3F6tyPEFEzV0LX3X8BsXdMsQz1x2cEikKDEY0aIj41qgxMCP/iteneqXSIFZBp5vizPvaoIR3Um9xK7PGoW8giupGn+EPuxIA4cDM4vzOqOkiMPhz5XK0whEjkVzTo4+S0puvDZuwIsdiW9mxhJc7tgBNL0cYlWSYVkz4G/fslNfRPW5mYAM49f4fhtxPb5ok4Q2Lg9dPKVHO/Bgeu5woMc7RY0p1ej6D4CKFE6lymSDJpW0YHX/wqE9+cfEauh7xZcG0q9t2ta6F6fmX0agvpFyZo8aFbXeUBr7osSCJNgvavWbM/06niWrOvYX2xwWdhXmXSrbX8ZbabVohBK41 email@example.com"
}
 
resource "aws_instance" "test-server" {
  ami           = "ami-05c13eab67c5d8861"
  availability_zone = "ap_south_1a"
  instance_type = "t2.micro"
  subnet_id = "${aws_subnet.public-subnet.id}"
  security_group = ["${aws_security_group.test_access.name}"]
  key_name = "my-key"

 
  tags = {
    Name = "test-server"
    Stage = "testing"
    Location = "chennai"
  }
}
 
resource "aws_eip" "my-ec2-eip" {
  instance = aws_instance.test-server.id
}
 
resource "aws_instance" "data-server" {
  ami           = "ami-05c13eab67c5d8861"
  availability_zone = "ap_south_1a"
  instance_type = "t2.micro"
  subnet_id = "${aws_subnet.private-subnet.id}"
  security_group = ["${aws_security_group.test_access.name}"]
  key_name = "my-key"

 
  tags = {
    Name = "data-server"
    Stage = "data-base"
    Location = "delhi"
  }
}
 
resource "aws_eip" "nat-eip"{
}
 
resource "aws_nat_gateway" "nat-gw" {
  allocation_id = aws_eip.nat-eip.id
  subnet_id     = aws_subnet.public-subnet.id
}
 
 
resource "aws_route_table" "private-route" {
  vpc_id = aws_vpc.test-vpc.id
 
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.nat-gw.id
  }
 
  tags = {
    Name = "private-route"
  }
}
 
resource "aws_route_table_association" "private-assoc" {
  subnet_id      = aws_subnet.private-subnet.id
  route_table_id = aws_route_table.private-route.id
}
