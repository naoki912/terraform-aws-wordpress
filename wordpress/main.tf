# Create a VPC for wordpress
resource "aws_vpc" "wp_vpc" {
  cidr_block = "10.0.0.0/16"
  instance_tenancy = "default"

  tags {
    Name = "wp_vpc"
  }
}

# Create an Internet gateway for wordpress
resource "aws_internet_gateway" "wp_gateway" {
  vpc_id = "${aws_vpc.wp_vpc.id}"

  tags {
    Name = "wp_gateway"
  }
}

# Set default route
resource "aws_route" "wp_internet_access" {
  route_table_id = "${aws_vpc.wp_vpc.default_route_table_id}"
  destination_cidr_block = "0.0.0.0/0"
  gateway_id = "${aws_internet_gateway.wp_gateway.id}"
}

# Create a public subnet (1a)
resource "aws_subnet" "wp_public_subnet_a1" {
  vpc_id = "${aws_vpc.wp_vpc.id}"
  cidr_block = "10.0.0.0/24"
  availability_zone = "ap-northeast-1a"

  tags {
    Name = "wp_public_subnet_1a"
  }
}

# Create a public subnet (1c)
resource "aws_subnet" "wp_public_subnet_a3" {
  vpc_id = "${aws_vpc.wp_vpc.id}"
  cidr_block = "10.0.1.0/24"
  availability_zone = "ap-northeast-1c"

  tags {
    Name = "wp_public_subnet_1c"
  }
}

# Create a private subnet (1a)
resource "aws_subnet" "wp_private_subnet_a1" {
  vpc_id = "${aws_vpc.wp_vpc.id}"
  cidr_block = "10.0.16.0/24"
  availability_zone = "ap-northeast-1a"

  tags {
    Name = "wp_private_subnet_1a"
  }
}

# Create a private subnet (1c)
resource "aws_subnet" "wp_private_subnet_a3" {
  vpc_id = "${aws_vpc.wp_vpc.id}"
  cidr_block = "10.0.17.0/24"
  availability_zone = "ap-northeast-1c"

  tags {
    Name = "wp_private_subnet_1c"
  }
}

# Create RDS db subnet group
resource "aws_db_subnet_group" "wp_db_subnet_group" {
  name = "wp_db_subnet_group"
  subnet_ids = [
    "${aws_subnet.wp_private_subnet_a1.id}",
    "${aws_subnet.wp_private_subnet_a3.id}",
  ]

  tags {
    Name = "wp_db_subnet_group"
  }
}

# Create WordPress security group (SSH, HTTP, HTTPS)
resource "aws_security_group" "wp_wordpress_security_group" {
  name = "wp_wordpress_security_group"
  description = "Allow Wordpress http and https"
  vpc_id = "${aws_vpc.wp_vpc.id}"

  # Allow SSH
  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = [
      "0.0.0.0/0"]
  }

  # Allow HTTP
  ingress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = [
      "0.0.0.0/0"]
  }

  # Allow HTTPS
  #ingress {
  #  from_port = 443
  #  to_port = 443
  #  protocol = "tcp"
  #  cidr_blocks = [
  #    "0.0.0.0/0"]
  #}

  # outbound internet access
  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = [
      "0.0.0.0/0"]
  }

  tags {
    Name = "wp_wordpress_security_group"
  }
}

# Create RDS security group (MySQL)
resource "aws_security_group" "wp_db_security_group" {
  name = "wp_db_security_group"
  description = "Allow DB 3306"
  vpc_id = "${aws_vpc.wp_vpc.id}"

  # Allow MySQL
  ingress {
    from_port = 3306
    to_port = 3306
    protocol = "tcp"
    security_groups = [
      "${aws_security_group.wp_wordpress_security_group.id}"]
  }

  # outbound internet access
  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = [
      "0.0.0.0/0"]
  }

  tags {
    Name = "wp_db_security_group"
  }
}

# Define public key
resource "aws_key_pair" "auth_key" {
  key_name = "${var.ssh_public_key_name}"
  public_key = "${file(var.ssh_public_key_path)}"
}

# Create a MySQL instance
resource "aws_db_instance" "wp_db_instance" {
  allocated_storage = 5
  engine = "mysql"
  engine_version = "5.7.16"
  instance_class = "db.t2.micro"
  identifier = "wpdb"
  name = "wp_db"
  username = "${var.aws_db_instance_username}"
  password = "${var.aws_db_instance_password}"
  parameter_group_name = "default.mysql5.7"
  db_subnet_group_name = "${aws_db_subnet_group.wp_db_subnet_group.name}"
  vpc_security_group_ids = [
    "${aws_security_group.wp_db_security_group.id}"
  ]

  tags {
    Name = "wp_db_instance"
  }
}

data "template_file" "init" {
  template = "${file("${path.module}/user_data.sh.tpl")}"

  vars {
    name = "${aws_db_instance.wp_db_instance.name}"
    user = "${aws_db_instance.wp_db_instance.username}"
    password = "${aws_db_instance.wp_db_instance.password}"
    host = "${aws_db_instance.wp_db_instance.address}"
  }
}

# Create a wordpress instance
resource "aws_instance" "wp_wordpress_instance" {
  connection {
    type = "ssh"
    user = "ubuntu"
    private_key = "${file(var.ssh_private_key_path)}"
  }

  instance_type = "t2.micro"

  ami = "${var.aws_wordpress_ami}"

  key_name = "${aws_key_pair.auth_key.id}"

  vpc_security_group_ids = [
    "${aws_security_group.wp_wordpress_security_group.id}"
  ]

  subnet_id = "${aws_subnet.wp_public_subnet_a1.id}"

  associate_public_ip_address = true

  user_data = "${data.template_file.init.rendered}"

  tags {
    Name = "wp_wordpress_instance"
  }
}
