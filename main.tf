data "aws_vpc" "main" {
  id = var.vpc_id
}

resource "aws_security_group" "sg_my_server" {
  name        = "sg_my_server"
  description = "MyServer security group"
  vpc_id      = data.aws_vpc.main.id

  ingress = [
    {
      description      = "HTTP"
      from_port        = 80
      to_port          = 80
      protocol         = "tcp"
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = []
      prefix_list_ids  = []
      security_groups  = []
      self             = false
    },
    {
      description      = "SSH"
      from_port        = 22
      to_port          = 22
      protocol         = "tcp"
      cidr_blocks      = [var.my_ip_with_cidr]
      ipv6_cidr_blocks = []
      prefix_list_ids  = []
      security_groups  = []
      self             = false
    }
  ]

  egress {
    description      = "outgoing traffic"
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
    prefix_list_ids  = []
    security_groups  = []
    self             = false
  }
}

resource "aws_key_pair" "deployer" {
  key_name   = "deployer-key"
  public_key = var.public_key
}

data "template_file" "user_data" {
  template = file("${abspath(path.module)}/userdata.yml")
}

resource "aws_instance" "my_server" {
  ami                    = "ami-006dcf34c09e50022"
  instance_type          = "t2.micro"
  key_name               = aws_key_pair.deployer.key_name
  vpc_security_group_ids = [aws_security_group.sg_my_server.id]
  user_data              = data.template_file.user_data.rendered

  // Local-exec allows to execute local commands after a resource is provisioned
  provisioner "local-exec" {
    command = "echo ${self.private_ip} >> private_ips.txt"
  }

  // Allows to execute commands on a target resource, after a resource has been provisioned
  provisioner "remote-exec" {
    inline = [
      "echo ${self.private_ip} >> /home/ec2-user/private_ips.txt"
    ]
    connection {
      type        = "ssh"
      user        = "ec2-user"
      host        = self.public_ip
      private_key = file("/home/yashgangwar123/.ssh/terraform")
    }
  }
  
  // File Provisioner: copy files or directories from our local machines to the newly created resource.
  provisioner "file" {
    content     = "ami used: ${self.ami}"
    destination = "/home/ec2-user/barsoon.txt"
    connection {
      type        = "ssh"
      user        = "ec2-user"
      host        = self.public_ip
      private_key = file("/home/yashgangwar123/.ssh/terraform")
    }
  }

  tags = {
    Name = var.server_name
  }
}

// This null resource will keep running still all checks are passed for ec2 instance after its creation 
resource "null_resource" "status" {
  provisioner "local-exec" {
    command = "aws ec2 instance-status-ok --instance-ids ${aws_instance.my_server.id}"
  }
  depends_on = [
    aws_instance.my_server
  ]
}

