data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_security_group" "demo" {
  name = "demo-ec2-${var.name}"

  tags = {
    Name = "demo-ec2-${var.name}"
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "demo" {
  instance_type               = "t3.small"
  associate_public_ip_address = true
  vpc_security_group_ids      = [aws_security_group.demo.id]

  ami = data.aws_ami.ubuntu.id

  tags = {
    Name = "demo-ec2-${var.name}"
  }

  user_data = <<-EOT
    #cloud-config
    runcmd:
      # store Vault SSH public key
      - curl -o /etc/ssh/trusted-user-ca-keys.pem ${var.vault_addr}/v1/ssh/public_key

      # modify sshd_config
      - echo "TrustedUserCAKeys /etc/ssh/trusted-user-ca-keys.pem" >> /etc/ssh/sshd_config

      # restart sshd
      - systemctl restart sshd

      - echo "Mon Jun 17 07:25:35 PDT 2024 - hello world!" > /var/log/example.log
      - echo "Mon Jun 17 07:25:36 PDT 2024 - foo bar" >> /var/log/example.log
      - chmod 664 /var/log/example.log
  EOT
}
