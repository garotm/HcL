provider "aws" {
  region = "us-east-1"
}

resource "aws_instance" "win_ec2" {
  ami           = "ami-0c94855ba95c71c99" # Windows Server 2019 Base AMI
  instance_type = "t3.medium"
  key_name      = "my_key_pair"

  vpc_security_group_ids = [aws_security_group.win_ec2.id]

  user_data = <<-EOF
    <powershell>
      # Install IIS
      Install-WindowsFeature -Name Web-Server -IncludeManagementTools

      # Enable RDP
      Set-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server' -name "fDenyTSConnections" -Value 0
      Enable-NetFirewallRule -DisplayGroup "Remote Desktop"
    </powershell>
  EOF

  tags = {
    Name = "win-ec2"
  }
}

resource "aws_security_group" "win_ec2" {
  name_prefix = "win-ec2-sg"

  ingress {
    from_port = 3389
    to_port   = 3389
    protocol  = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "win-ec2-sg"
  }
}

resource "aws_iam_instance_profile" "win_ec2_profile" {
  name = "win-ec2-profile"

  role {
    name = "win-ec2-role"
    policy = jsonencode({
      Version = "2012-10-17",
      Statement = [
        {
          Action = [
            "s3:GetObject",
            "s3:PutObject",
            "s3:ListBucket"
          ],
          Effect = "Allow",
          Resource = [
            "arn:aws:s3:::my-bucket",
            "arn:aws:s3:::my-bucket/*"
          ]
        }
      ]
    })
  }
}

resource "aws_iam_role" "win_ec2_role" {
  name = "win-ec2-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

output "win_ec2_private_ip" {
  value = aws_instance.win_ec2.private_ip
}

output "win_ec2_public_ip" {
  value = aws_instance.win_ec2.public_ip
}

