# Use existing Elastic IP
data "aws_eip" "creorez_eip" {
  public_ip = "54.168.170.151"
}

# Associate existing Elastic IP with new EC2
resource "aws_eip_association" "creorez_eip_assoc" {
  instance_id   = aws_instance.creorez_ec2.id
  allocation_id = data.aws_eip.creorez_eip.id
}