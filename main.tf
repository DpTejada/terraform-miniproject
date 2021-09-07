
####################### NETWORK #################################################################
resource "aws_vpc" "myapp-vpc" {
    cidr_block = "10.0.0.0/18"
    tags = {
      Name = "devops-vpc"
    }

  
}
resource "aws_subnet" "myapp-subnet-public" {
    vpc_id     = aws_vpc.myapp-vpc.id 
    cidr_block = "10.0.0.0/19"
    availability_zone = "us-east-1a"

    tags = {
      Name = "public_subnet1"
  }
  
}
resource "aws_subnet" "myapp-subnet-private" {
    vpc_id     = aws_vpc.myapp-vpc.id 
    cidr_block = "10.0.32.0/20"
    availability_zone = "us-east-1b"

    tags = {
      Name = "private_subnet1"
  }
  
}

resource "aws_route_table" "route-table-IG" {
  vpc_id = aws_vpc.myapp-vpc.id

  route {
      cidr_block = "0.0.0.0/0"
      gateway_id = aws_internet_gateway.myapp-igw.id   

  }

  tags = {
      Name: "ig-rtb"
      }
}

resource "aws_route_table" "route-table-NAT" {
  vpc_id = aws_vpc.myapp-vpc.id

  route {
      cidr_block = "0.0.0.0/0"
      gateway_id = aws_nat_gateway.my-nat.id   

  }

  tags = {
      Name: "nat-rtb"
      }
}

resource "aws_internet_gateway" "myapp-igw" {
    vpc_id = aws_vpc.myapp-vpc.id
    tags =  {
        Name: "my-igw"
    }
} 

resource "aws_eip" "eip-nat" {
  vpc = true
  tags = {
    Name  = "my-eip"
    Owner = "David"

  }
}


resource "aws_nat_gateway" "my-nat" {
    allocation_id = aws_eip.eip-nat.id     
    subnet_id = aws_subnet.myapp-subnet-private.id    

    tags = {
        Name: "nat-gw"

    } 
  
}

resource "aws_route_table_association" "rtb-subnet-public" {
    subnet_id = aws_subnet.myapp-subnet-public.id  
    route_table_id = aws_route_table.route-table-IG.id  

}

resource "aws_route_table_association" "rtb-subnet-private" {
    subnet_id = aws_subnet.myapp-subnet-private.id  
    route_table_id = aws_route_table.route-table-NAT.id  

}

################################# SECURITY GROUP ############################################

resource "aws_security_group" "devops14_2021" {
  name        = "devops_sg"
  description = "dynamic-sg"
  vpc_id      = aws_vpc.myapp-vpc.id
  dynamic "ingress" {
      for_each = var.ingress_ports
     content {
          from_port = ingress.value
          to_port = ingress.value
          protocol = "tcp"
          cidr_blocks = ["0.0.0.0/0"]
      } 
  }
  egress {
     
        from_port = 0
        to_port = 65535
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
        prefix_list_ids = []
       
  }

  
  
  tags = {
    Name = "devops-dynamic-sg"
  }
}
########################### DATA ##########################################################################
data "aws_ami" "latest-amazon-linux-image" {
    most_recent = true
    owners = ["amazon"]
    filter {
        name = "name"
        values = ["amzn2-ami-hvm-*x86_64-gp2"]
    }
     filter {
        name = "virtualization-type"
        values = ["hvm"]
    }
}

############################# EC2 ############################################################################
resource "aws_instance" "devops-ec2" {
    count = 1
  ami           = data.aws_ami.latest-amazon-linux-image.id 
  instance_type = var.instance_type[count.index]
  subnet_id = aws_subnet.myapp-subnet-public.id
  vpc_security_group_ids = [aws_security_group.devops14_2021.id] 
  key_name      = aws_key_pair.my-key.key_name
  associate_public_ip_address = true
  
  tags = {
    "Name" = element(var.tags, count.index)
  }

connection {
    type = "ssh"
    host = self.public_ip
    user = "ec2-user"
    private_key = file(var.private_key_location)
}
  provisioner "file" {
    source = "/root/miniproject/apache-configuration.sh"
    destination = "/home/ec2-user/apache-configuration.sh"

}

  provisioner "remote-exec" {
     #script = file("apache-configuration.sh")
        inline = [
        "sudo chmod 777 /home/ec2-user/apache-configuration.sh",
         "sh /home/ec2-user/apache-configuration.sh",
    ]
   
}
  
}

resource "aws_instance" "ec2-in-private01" {
    count = 1
  ami           = data.aws_ami.latest-amazon-linux-image.id 
  instance_type = var.instance_type[count.index]
  subnet_id = aws_subnet.myapp-subnet-private.id
  vpc_security_group_ids = [aws_security_group.devops14_2021.id] 
  key_name      = aws_key_pair.my-key.key_name
  associate_public_ip_address = true
  
  tags = {
    "Name" = element(var.tags, 2)
  }

  provisioner "local-exec" {
     command = "echo ${aws_instance.ec2-in-private01[count.index].public_ip} >> my_public_ips.txt"

   
}

  
}


resource "aws_key_pair" "my-key" {
  key_name   = "devops14_2021"
  public_key = file(var.public_key_location)
}


output "ec2_elastic-ip" {
    value = aws_eip.eip-nat.public_ip
}
output "public_ips" {
    value = "${join(",", aws_instance.devops-ec2.*.public_ip)}"
    
}
