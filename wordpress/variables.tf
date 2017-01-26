# provider aws
variable "aws_access_key" {}
variable "aws_secret_key" {}
variable "aws_region" {}

# amis
variable "aws_wordpress_ami" {
    default = "ami-be4a24d9"
}

# aws_key_pair
variable "ssh_public_key_name" {}
variable "ssh_public_key_path" {}
variable "ssh_private_key_path" {}

# RDS parametor
variable "aws_db_instance_username" {}
variable "aws_db_instance_password" {}

# user-data
variable "aws_instance_user_data" {
    default = "./user_data.sh.tpl"
}
