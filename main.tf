resource "aws_vpc" "my_vpc" {
  cidr_block = "192.168.0.0/24"
}

resource "aws_internet_gateway" "ig" {
  vpc_id = aws_vpc.my_vpc.id
}

resource "aws_route_table" "rt" {
  vpc_id = aws_vpc.my_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.ig.id
  }
}

resource "aws_route_table_association" "rta_subnet_public" {
  subnet_id      = aws_subnet.my_subnet.id
  route_table_id = aws_route_table.rt.id
}


resource "aws_subnet" "my_subnet" {
  vpc_id                  = aws_vpc.my_vpc.id
  cidr_block              = "192.168.0.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = "true"
}


resource "aws_key_pair" "aws_key" {
  key_name   = "key_aws"
  public_key = file("${var.public_key}")
}

resource "aws_security_group" "sg" {
  vpc_id = aws_vpc.my_vpc.id

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

}

resource "aws_instance" "linux_vm" {
  ami           = "ami-04505e74c0741db8d"
  instance_type = "t2.micro"

  key_name = "key_aws"

  vpc_security_group_ids = [aws_security_group.sg.id]

  subnet_id = aws_subnet.my_subnet.id

  provisioner "local-exec" {
    command = "ansible-playbook -u ubuntu -i '${self.public_ip}', --key-file=${var.private_key} ./ansible/main.yml --extra-vars 'ip=${self.public_ip}'"
  }

}

