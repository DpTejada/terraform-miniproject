resource "aws_vpc" "myapp-vpc" {
    cidr_block = "10.0.0.0/18"
    tags = {
      Name = "devops-vpc"
    }

  
}
resource "aws_subnet" "myapp-subnet" {
    vpc_id     = aws_vpc.myapp-vpc.id 
    cidr_block = "10.0.0.0/19"
    availability_zone = "us-east-1a"

    tags = {
      Name = "devops_subnet1"
  }
  
}

resource "aws_route_table" "myapp-route-table" {
  vpc_id = aws_vpc.myapp-vpc.id

  route {
      cidr_block = "0.0.0.0/0"
      gateway_id = aws_internet_gateway.myapp-igw.id   

  }

  tags = {
      Name: "devops-rtb"
      }
}

resource "aws_internet_gateway" "myapp-igw" {
    vpc_id = aws_vpc.myapp-vpc.id
    tags =  {
        Name: "devops-igw"
    }
} 

resource "aws_route_table_association" "a-rtb-subnet" {
    subnet_id = aws_subnet.myapp-subnet.id  
    route_table_id = aws_route_table.myapp-route-table.id  

}

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

resource "aws_instance" "devops-ec2" {
    count = 2
  ami           = data.aws_ami.latest-amazon-linux-image.id 
  instance_type = var.instance_type[count.index]
  subnet_id = aws_subnet.myapp-subnet.id
  vpc_security_group_ids = [aws_security_group.devops14_2021.id] 
  key_name      = aws_key_pair.my-key.key_name
  associate_public_ip_address = true
  
  tags = {
    "Name" = element(var.tags, count.index)
  }

connection {
    type = "ssh"
    host = "${self.private_ip}"
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

resource "aws_key_pair" "my-key" {
  key_name   = "devops14_2021"
  public_key = file(var.public_key_location)
}



# resource "aws_eip" "my_eip" {
#   instance = aws_instance.devops-ec2.id   
#   vpc = true
#   tags = {
#     Name  = "devops14_2021"
#     Owner = "David"

#   }
# }

# output "ec2_elastic-ip" {
#     value = aws_eip.my_eip.public_ip
# }
output "public_ips" {
    value = "${join(",", aws_instance.devops-ec2.*.public_ip)}"
    
}
