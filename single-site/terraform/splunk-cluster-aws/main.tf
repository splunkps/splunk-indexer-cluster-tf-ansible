variable "master_count" {
  description = "Number of EC2 instances to create for splunk manager"
  # it would be 1 ideally
  default     = 1
}

# variable "deployer_count" {
#   description = "Number of EC2 instances to create for splunk manager"
#   # it would be 1 ideally for 1 search head cluster
#   default     = 1
# }

variable "indexer_count" {
  description = "Number of EC2 instances to create for splunk Indexer cluster"
  # it can be anything. for testing 3 is ideal number
  default     = 3
}

variable "searchhead_count" {
  description = "Number of EC2 instances to create for splunk sh cluster"
  # it can be anything. for testing 3 is ideal number. for standardlone search head make it 1.
  default     = 1
}

resource "aws_instance" "master" {
  count         = var.master_count
  ami           = "ami-0713848d3031ddec5"  # Replace with the desired AMI ID
  instance_type = "t2.micro"      # Replace with the desired instance type
  subnet_id     = "subnet-071cb64e0883adb7b"  # Replace with the desired subnet ID
  key_name      = "<pem_file_in_aws_to_be_given_acces_to_this_instance>"

  root_block_device {
    volume_size = 50
  }

  user_data = <<-EOF
  #!/bin/bash
  echo "Setting hostname..."
  hostnamectl set-hostname "splunkcm-${count.index+1}"
  echo "Hostname set to splunkcm-${count.index+1}"
  EOF

  tags = {
    Name = "splunkcm-${count.index+1}"
    Role = "Manager"
  }

  vpc_security_group_ids = [aws_security_group.ec2_sg.id]
}

#resource "aws_instance" "deployer" {
#  count         = var.deployer_count
#  ami           = "ami-0713848d3031ddec5"  # Replace with the desired AMI ID
#  instance_type = "t2.micro"      # Replace with the desired instance type
#  subnet_id     = "subnet-071cb64e0883adb7b"  # Replace with the desired subnet ID
#  key_name      = "<pem_file_in_aws_to_be_given_acces_to_this_instance>"

#  root_block_device {
#   volume_size = 50
#  }

#  tags = {
#    Name = "splunkdpr-${count.index+1}"
#  }

#  vpc_security_group_ids = [aws_security_group.ec2_sg.id]
#}


resource "aws_instance" "indexer" {
  count         = var.indexer_count
  ami           = "ami-0713848d3031ddec5"  # Replace with the desired AMI ID
  instance_type = "t2.micro"      # Replace with the desired instance type
  subnet_id     = "subnet-071cb64e0883adb7b"  # Replace with the desired subnet ID
  key_name      = "<pem_file_in_aws_to_be_given_acces_to_this_instance>"

  root_block_device {
    volume_size = 50
  }

  user_data = <<-EOF
  #!/bin/bash
  echo "Setting hostname..."
  hostnamectl set-hostname "splunkidxr-${count.index+1}"
  echo "Hostname set to splunkidxr-${count.index+1}"
  EOF

  tags = {
    Name = "splunkidxr-${count.index+1}"
    Role = "Indexer"
  }

  vpc_security_group_ids = [aws_security_group.ec2_sg.id]
}

resource "aws_instance" "searchhead" {
  count         = var.searchhead_count
  ami           = "ami-0713848d3031ddec5"  # Replace with the desired AMI ID
  instance_type = "t2.micro"      # Replace with the desired instance type
  subnet_id     = "subnet-071cb64e0883adb7b"  # Replace with the desired subnet ID
  key_name      = "<pem_file_in_aws_to_be_given_acces_to_this_instance>"

  root_block_device {
    volume_size = 50
  }

  tags = {
    Name = "splunksh-${count.index+1}"
    Role = "Searchhead"
  }

  user_data = <<-EOF
  #!/bin/bash
  echo "Setting hostname..."
  hostnamectl set-hostname "splunksh-${count.index+1}"
  echo "Hostname set to splunksh-${count.index+1}"
  EOF

  vpc_security_group_ids = [aws_security_group.ec2_sg.id]
}


resource "aws_security_group" "ec2_sg" {
  name        = "splunk-sg"
  description = "Security Group for EC2 instances created for splunk using tf"

  ingress {
    from_port   = 8000
    to_port     = 8000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    self        = true
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    self        = true
  }
}

resource "null_resource" "write_public_ips_master" {
  count = var.master_count

  provisioner "local-exec" {
    command = <<-EOT
      echo 'master' >> public_ips.txt
      echo '${aws_instance.master.*.public_ip[count.index]}' >> public_ips.txt
    EOT
  }
}

# resource "null_resource" "write_public_ips_deployer" {
#   count = var.deployer_count

#   provisioner "local-exec" {
#     command = <<-EOT
#       echo 'deployer' >> public_ips.txt
#       echo '${aws_instance.deployer.*.public_ip[count.index]}' >> public_ips.txt
#     EOT
#   }
# }

resource "null_resource" "write_public_ips_indexer" {
  count = var.indexer_count

  provisioner "local-exec" {
    command = <<-EOT
      echo 'indexer' >> public_ips.txt
      echo '${aws_instance.indexer.*.public_ip[count.index]}' >> public_ips.txt
    EOT
  }
}

resource "null_resource" "write_public_ips_searchhead" {
  count = var.searchhead_count

  provisioner "local-exec" {
    command = <<-EOT
      echo 'searchhead' >> public_ips.txt
      echo '${aws_instance.searchhead.*.public_ip[count.index]}' >> public_ips.txt
    EOT
  }
}
