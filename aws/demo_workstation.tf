resource "aws_instance" "aws-centos7-workstation" {
  connection {
    user        = "centos"
    private_key = "${file("${var.aws_key_pair_file}")}"
    host = self.public_ip
  }
  ami                         = "${data.aws_ami.centos7.id}"
  instance_type               = "t2.medium"
  key_name                    = "${var.aws_key_pair_name}"
  subnet_id                   = "${aws_subnet.habmgmt-subnet-a.id}"
  vpc_security_group_ids      = ["${aws_security_group.chef_automate.id}"]
  associate_public_ip_address = true

  depends_on = ["aws_instance.chef_automate"]

  tags = {
    Name          = "ccl-${terraform.workspace}-aws-centos7-workstation"
    X-Dept        = "${var.tag_dept}"
    X-Customer    = "${var.tag_customer}"
    X-Project     = "${var.tag_project}"
    X-Application = "${var.tag_application}"
    X-Contact     = "${var.tag_contact}"
    X-TTL         = "${var.tag_ttl}"
  }

  provisioner "file" {
    content     = "${data.template_file.install_hab.rendered}"
    destination = "/tmp/install_hab.sh"
  }

  provisioner "file" {
    content     = "${data.template_file.sup_service.rendered}"
    destination = "/home/centos/hab-sup.service"
  }

  provisioner "file" {
    content     = "${data.template_file.linux_baseline.rendered}"
    destination = "/home/centos/linux_baseline.toml"
  }

  provisioner "file" {
    content     = "${data.template_file.chef-base.rendered}"
    destination = "/home/centos/chef-base.toml"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo rm -rf /etc/machine-id",
      "sudo systemd-machine-id-setup",
      "sudo hostname aws-centos",
      "sudo groupadd hab",
      "sudo adduser hab -g hab",
      "chmod +x /tmp/install_hab.sh",
      "sudo /tmp/install_hab.sh",
      "sudo hab license accept",
      "sudo yum install wget -y",
      "sudo wget https://packages.chef.io/files/stable/chef-workstation/0.2.53/el/7/chef-workstation-0.2.53-1.el6.x86_64.rpm",
      "sudo rpm -Uvh chef-workstation-0.2.53-1.el6.x86_64.rpm",
      "sudo yum update -y",
      "sudo yum install git -y",
      "sudo yum install tree -y",
      "sudo sed -i -e 's/PasswordAuthentication no/#PasswordAuthentication no/g' /etc/ssh/sshd_config",
      "sudo sed -i -e 's/PasswordAuthentication yes/PasswordAuthentication yes/g' /etc/ssh/sshd_config",
      "sudo service sshd restart",
      "sudo echo ${var.node_workstation_password} | sudo passwd --stdin centos",

    ]
  }
}

resource "aws_route53_record" "centos-wks" {
  zone_id = "${data.aws_route53_zone.selected.zone_id}"
  name    = "ccl-${terraform.workspace}-workstation.${var.automate_alb_r53_matcher}"
  type    = "CNAME"
  ttl     = "30"
  records = ["${aws_instance.aws-centos7-workstation.public_dns}"]
}

