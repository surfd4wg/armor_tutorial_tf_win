terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.42"
    }
  }

  required_version = ">= 0.14"
}

resource "aws_key_pair" "terraform_pub_key" {
  public_key = file("~/.ssh/surfkeywin.pub")
}

variable "private_key_path" {
  description = "Path to the private SSH key, used to access the instance."
  default     = "~/.ssh/surfkeywin.pem"
}

variable "instance_name" {
  description = "Value of the Name tag for the EC2 instance"
  type        = string
  default     = "ExampleAppServerInstance"
}

locals {
  user_data = <<EOF
  <powershell>
	#Armor Agent
	mkdir c:\armorinstall
	cd c:\armorinstall
	Invoke-WebRequest https://agent.armor.com/latest/armor_agent.ps1 -outfile c:\armorinstall\armor_agent.ps1
	New-Item -Path . -Name "armorinstall.ps1" -ItemType "file" -Value ".\armor_agent.ps1 -license XXXXX-XXXXX-XXXXX-XXXXX-XXXXX -region us-west-armor -full"
	.\armorinstall.ps1
  </powershell>
EOF
}

provider "aws" {
  profile = "default"
  region  = "us-east-1"
}

resource "aws_instance" "app_server" {
  ami           = "ami-0fa60543f60171fe3"
  instance_type = "t3.medium"

  user_data_base64 = base64encode(local.user_data)

  key_name = aws_key_pair.terraform_pub_key.key_name

  get_password_data = "true"

  tags = {
    Name = var.instance_name
  }
}

output "instance_id" {
  description = "ID of the EC2 instance"
  value       = aws_instance.app_server.id
}

output "instance_public_ip" {
  description = "Public IP address of the EC2 instance"
  value       = aws_instance.app_server.public_ip
}

output "Admin_Username" {
  value = "Administrator"
}

output "Admin_Password_Data" {
  value = aws_instance.app_server.password_data
}

output "Admin_Password_Data_Decrypted" {
  value = rsadecrypt(aws_instance.app_server.password_data, file(var.private_key_path))

}
