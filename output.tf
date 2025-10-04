# Output in the terminal the address of the Jenkins server, once it's created
output "public_ip" {
  value = aws_instance.jenkins-server.public_ip
}
output "Jenkins_url" {
  value = "http://${aws_instance.jenkins-server.public_ip}:8080"
  
}

output "ssh" {
  value = "ssh -i kk.pem ec2-user@${aws_instance.jenkins-server.public_ip}"
} 
