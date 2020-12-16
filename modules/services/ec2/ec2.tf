resource "aws_eip" "eip" {
 vpc = true  
 instance = aws_instance.ec2_instance.id
 tags = {
    Environment = var.environment_tag
    Name = "${var.prefix}-${terraform.workspace}-ec2-write-node"
  }
}
resource "aws_instance" "ec2_instance" {
  ami           = var.instance_ami
  instance_type = var.instance_type
 // iam_instance_profile = "iam_role_s3_instance_profile_s3"
 iam_instance_profile = "iam_role_s3_instance_profile_s3"
 
      //user_data = var.user_data_script
    //user_data = data.template_file.user_data.rendered
    user_data = <<-EOF
#!/bin/bash
yum update -y
yum install httpd php php-mysql -y
cd /var/www/html
echo "healthydd" > healthy.html
wget https://wordpress.org/wordpress-5.1.1.tar.gz
tar -xzf wordpress-5.1.1.tar.gz
cp -r wordpress/* /var/www/html/
rm -rf wordpress
rm -rf wordpress-5.1.1.tar.gz
chmod -R 755 wp-content
chown -R apache:apache wp-content
wget https://s3.amazonaws.com/bucketforwordpresslab-donotdelete/htaccess.txt
mv htaccess.txt .htaccess
chkconfig httpd on
service httpd start
EOF

  subnet_id = var.subnet_for_ec2 //aws_subnet.subnet_public_1.id
  vpc_security_group_ids = var.security_groups_for_ec2 //[aws_security_group.sg_22.id, aws_security_group.sg_8080.id, aws_security_group.sg_80.id]
  key_name = var.key_pair_for_ec2 //aws_key_pair.ec2key.key_name

 
  tags = {
    Environment = var.environment_tag
    Name = "${var.prefix}-${terraform.workspace}-ec2"
    Owner = var.owner_tag
  }
 
}