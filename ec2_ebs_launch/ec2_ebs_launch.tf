provider "aws" {
	region = "ap-south-1"
	profile = "default"
}

resource "aws_key_pair" "task-1-key-pair" {
  key_name   = "new-key-pair"
  public_key = file("/root/HMC_Task-1/keypair/new-key-pair.pub")
}
/*
resource "null_resource" "vpc_details"  {
	provisioner "local-exec" {
		command = "sudo aws --profile default  ec2 describe-vpcs --query 'Vpcs[0].VpcId' --output text > my_vpc_id.txt"
  	}
	provisioner "local-exec" {
		command = "sudo aws --profile default  ec2 describe-vpcs --query 'Vpcs[0].CidrBlock' --output text > my_vpc_cidr.txt"
  	}
}
*/

resource "aws_security_group" "task_1_security_group" {
/*  depends_on = [
		null_resource.vpc_details
	]
*/
  name        = "task_1_security_group"
  description = "Allow HTTP and SSH inbound traffic"
  vpc_id      = file("/root/HMC_Task-1/ec2_ebs_launch/my_vpc_id.txt")

  ingress {
    description = "SSH Connection"
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

  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "task_1_security_group"
  }
}


resource "aws_instance" "task_1_instance" {
  depends_on = [
		aws_security_group.task_1_security_group
	]
  ami           = "ami-0447a12f28fddb066"
  instance_type = "t2.micro"
  key_name = "new-key-pair"
  security_groups = ["${aws_security_group.task_1_security_group.name}"]

  connection {
    type     = "ssh"
    user     = "ec2-user"
    private_key = file("/root/HMC_Task-1/keypair/new-key-pair")
    host     = aws_instance.task_1_instance.public_ip
  }

  provisioner "remote-exec" {
    inline = [
      "sudo yum install httpd  php git -y",
      "sudo systemctl restart httpd",
      "sudo systemctl enable httpd",
    ]
  }

  tags = {
    Name = "task_1_instance"
  }

}

resource "aws_ebs_volume" "task_1_vol" {
	availability_zone = aws_instance.task_1_instance.availability_zone
	size = 1
	tags = {
		Name = "task_1_vol"
	}
}

resource "aws_volume_attachment" "task_1_vol_att" {
	device_name = "/dev/sdd"
	volume_id = aws_ebs_volume.task_1_vol.id
	instance_id = aws_instance.task_1_instance.id
	force_detach = true
}

output "task_1_instance_ip" {
	value = aws_instance.task_1_instance.public_ip
}

resource "null_resource" "instance_public_ip" {
	provisioner "local-exec" {
		command = "echo ${aws_instance.task_1_instance.public_ip} > my_ins_public_ip.txt"
	}
}

resource "null_resource" "ssh_conn" {
	depends_on = [
		aws_volume_attachment.task_1_vol_att
	]
	
	connection {
    type     = "ssh"
    user     = "ec2-user"
    private_key = file("/root/HMC_Task-1/keypair/new-key-pair")
    host     = aws_instance.task_1_instance.public_ip
  }

  provisioner "remote-exec" {
    inline = [
      "sudo mkfs.ext4 /dev/xvdd",
      "sudo mount /dev/xvdd /var/www/html",
      "sudo rm -rf /var/www/html/*",
      "sudo git clone https://Harishankar4274:I_do_not_use_passwords@github.com/Harishankar4274/my_web_pages.git /var/www/html"
    ]
  }
}


