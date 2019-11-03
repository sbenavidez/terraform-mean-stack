# Module to create a complete VPC 
module "vpc" {
  source = "../vpc-module/"

  # Parameters config 
  azs             = ["us-east-1a", "us-east-1b"]
  private_subnets = ["10.77.1.0/24", "10.77.2.0/24"]
  public_subnets  = ["10.77.101.0/24", "10.77.102.0/24"]

  cidr = "10.77.0.0/16"
  enable_nat_gateway = false
  enable_dhcp_options = true 
  enable_dns_hostnames = true 
  enable_dns_support = true 

  #Seteo de tags
  name="App-SB"
  vpc_tags = { Name = "VPC-app-SB" }
  igw_tags = { Name = "App-SB-IGW" }
  public_route_table_tags = { Name = "App-SB-Public" }
  private_route_table_tags = { Name = "App-SB-Private" }

  tags = {
    MNGT = "Terraform"
    Environment = "DEV"
    CreatedBy = "SBenavidez"
  }
}

# Security group for Express and Mongo server
resource "aws_security_group" "App-Mean-SB" {

  name = "App-Mean-SB"
  description = "Allow SSH Access"
  vpc_id = module.vpc.vpc_id

  ingress {
    cidr_blocks = [
        "0.0.0.0/0"
      ]
    from_port = 22
    to_port = 22
    protocol = "tcp"
    description = "SSH Accesss"
  }

  ingress {
    cidr_blocks = [
        "0.0.0.0/0"
      ]
    from_port = 3000
    to_port = 3000
    protocol = "tcp"
    description = "nodeJS Express "
  }

  ingress {
    cidr_blocks = [
        "0.0.0.0/0"
      ]
    from_port = 27017
    to_port = 27017
    protocol = "tcp"
    description = "MongoDB Access"
  }

  // Terraform removes the default rule
  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    MNGT = "Terraform"
    Environment = "DEV"
    CreatedBy = "SBenavidez"
    Name = "App-Mean-SB-SG"
  }
}


# NodeJS Express backend and MongoDB
resource "aws_instance" "App-Mean-Test-SB" {
  ami           = "ami-0b69ea66ff7391e80" # AWS Amazon Linux on us-east-1
  instance_type = "t2.nano"
  key_name = "latam-SB-santiago"

  vpc_security_group_ids = ["${aws_security_group.App-Mean-SB.id}"]
  subnet_id = "${module.vpc.public_subnets[0]}"
  associate_public_ip_address = true 

  root_block_device {
    volume_type = "gp2"
    volume_size = "8"
    delete_on_termination = true
  }

  tags = {
    MNGT = "Terraform"
    Environment = "DEV"
    CreatedBy = "SBenavidez"
    Name = "App-Mean-Test-SB"
  }

  volume_tags = {
    MNGT = "Terraform"
    Environment = "DEV"
    CreatedBy = "SBenavidez"
    Name = "App-Mean-Test-SB"
  }

  user_data = <<EOF
            #! /bin/bash
            exec >> /home/ec2-user/user-data.log 2>&1

            #install nodeJS
            sudo yum -y update
            cd /home/ec2-user/
            sudo yum install -y gcc-c++ make
            curl -sL https://rpm.nodesource.com/setup_11.x | sudo -E bash -
            sudo yum install -y nodejs

            #install git
            sudo yum -y install git

            #Install express and mongoose libs
            npm install express mongoose

          EOF

  lifecycle {
    prevent_destroy = true
    ignore_changes = [user_data]
  }

}

# Front End Anglugar Layer
resource "aws_s3_bucket" "App-Mean-Test-SB" {
  bucket = "app-mean-test-sb"
  acl    = "public-read"

  website {
    index_document = "index.html"
    error_document = "error.html"
  }  
}

# Security group for jenkins server
resource "aws_security_group" "jenkins-Mean-SB" {

  name = "jenkins-mean-SB"
  description = "Allow SSH Access"
  vpc_id = module.vpc.vpc_id

  ingress {
    cidr_blocks = [
        "0.0.0.0/0"
      ]
    from_port = 22
    to_port = 22
    protocol = "tcp"
    description = "SSH Accesss"
  }

  ingress {
    cidr_blocks = [
        "0.0.0.0/0"
      ]
    from_port = 8080
    to_port = 8080
    protocol = "tcp"
    description = "Jenkins Accesss"
  }

  // Terraform removes the default rule
  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    MNGT = "Terraform"
    Environment = "DEV"
    CreatedBy = "SBenavidez"
    Name = "jenkins-Mean-SB-SG"
  }
}

# NodeJS Express backend and MongoDB
resource "aws_instance" "jenkins" {
  ami           = "ami-0b69ea66ff7391e80" # AWS Amazon Linux on us-east-1
  instance_type = "t2.nano"
  key_name = "latam-SB-santiago"
  iam_instance_profile = "${aws_iam_instance_profile.jenkins-profile.name}"

  vpc_security_group_ids = ["${aws_security_group.jenkins-Mean-SB.id}"]
  subnet_id = "${module.vpc.public_subnets[0]}"
  associate_public_ip_address = true 

  root_block_device {
    volume_type = "gp2"
    volume_size = "8"
    delete_on_termination = true
  }

  tags = {
    MNGT = "Terraform"
    Environment = "DEV"
    CreatedBy = "SBenavidez"
    Name = "jenkins-server"
  }

  volume_tags = {
    MNGT = "Terraform"
    Environment = "DEV"
    CreatedBy = "SBenavidez"
    Name = "jenkins-server"
  }

  user_data = <<EOF
            #! /bin/bash
            exec >> /home/ec2-user/user-data.log 2>&1

            #install nodeJS
            sudo yum -y update
            cd /home/ec2-user/
            sudo yum install -y gcc-c++ make
            curl -sL https://rpm.nodesource.com/setup_11.x | sudo -E bash -
            sudo yum install -y nodejs

            #install git
            sudo yum -y install git

            #Install express and mongoose libs
            npm install -g @angular/cli 

            #install jenkins
            sudo yum remove java-1.7.0-openjdk -y
            sudo yum install java-1.8.0 -y

            sudo wget -O /etc/yum.repos.d/jenkins.repo http://pkg.jenkins-ci.org/redhat/jenkins.repo
            sudo rpm --import http://pkg.jenkins-ci.org/redhat/jenkins-ci.org.key

            echo 'installing jenkins.......'

            sudo yum install jenkins -y

            echo 'configuring service.......'

            sudo service jenkins start
            chkconfig jenkins on

            ## Agregar sudoers para user Jenkins
          EOF

  lifecycle {
    prevent_destroy = true
    ignore_changes = [user_data]
  }

}

resource "aws_iam_role" "jenkins-role" {
  name = "jenkins-role"

  assume_role_policy =<<EOF
{
      "Version": "2012-10-17",
      "Statement": [
        {
          "Action": "sts:AssumeRole",
          "Principal": {
            "Service": "ec2.amazonaws.com"
          },
          "Effect": "Allow",
          "Sid": ""
        }
      ]
}
EOF

  tags = {
    MNGT = "Terraform"
    Environment = "DEV"
    CreatedBy = "SBenavidez"
    Name = "jenkins-role"
  }
}

resource "aws_iam_role_policy" "jenkins_policy" {
  name = "jenkins_policy"
  role = "${aws_iam_role.jenkins-role.id}"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "s3:*"
      ],
      "Effect": "Allow",
      "Resource": "*"
    }
  ]
}
EOF
}

resource "aws_iam_instance_profile" "jenkins-profile" {                             
  name  = "jenkins-profile"                         
  role = "${aws_iam_role.jenkins-role.name}"
}