# Fetching AWS Key Pair

resource "aws_key_pair" "splunk_key" {
  key_name   = "Demo-key"
  public_key = file("~/.ssh/id_rsa.pub") # Provide the path to your public key file
}


