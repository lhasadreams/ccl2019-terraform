resource "aws_security_group" "chef_automate" {
  name        = "chef_automate_${random_id.instance_id.hex}"
  description = "Chef Automate Server"
  vpc_id      = "${aws_vpc.habmgmt-vpc.id}"

  tags = {
    Name          = "ccl-${terraform.workspace}-aws-sg"
    X-Dept        = "${var.tag_dept}"
    X-Customer    = "${var.tag_customer}"
    X-Project     = "${var.tag_project}"
    X-Application = "${var.tag_application}"
    X-Contact     = "${var.tag_contact}"
    X-TTL         = "${var.tag_ttl}"
  }
}

//////////////////////////
// Base Linux Rules
resource "aws_security_group_rule" "ingress_allow_22_tcp_all" {
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = "${aws_security_group.chef_automate.id}"
}

/////////////////////////
// Habitat Supervisor Rules
# Allow Habitat Supervisor http communication tcp
resource "aws_security_group_rule" "ingress_allow_9631_tcp" {
  type                     = "ingress"
  from_port                = 9631
  to_port                  = 9631
  protocol                 = "tcp"
  security_group_id        = "${aws_security_group.chef_automate.id}"
  source_security_group_id = "${aws_security_group.chef_automate.id}"
}

# Allow Habitat Supervisor http communication udp
resource "aws_security_group_rule" "ingress_allow_9631_udp" {
  type                     = "ingress"
  from_port                = 9631
  to_port                  = 9631
  protocol                 = "udp"
  security_group_id        = "${aws_security_group.chef_automate.id}"
  source_security_group_id = "${aws_security_group.chef_automate.id}"
}

# Allow Habitat Supervisor ZeroMQ communication tcp
resource "aws_security_group_rule" "ingress_9638_tcp" {
  type                     = "ingress"
  from_port                = 9638
  to_port                  = 9638
  protocol                 = "tcp"
  security_group_id        = "${aws_security_group.chef_automate.id}"
  source_security_group_id = "${aws_security_group.chef_automate.id}"
}

# Allow Habitat Supervisor ZeroMQ communication udp
resource "aws_security_group_rule" "ingress_allow_9638_udp" {
  type                     = "ingress"
  from_port                = 9638
  to_port                  = 9638
  protocol                 = "udp"
  security_group_id        = "${aws_security_group.chef_automate.id}"
  source_security_group_id = "${aws_security_group.chef_automate.id}"
}

////////////////////////////////
// Chef Automate Rules
# HTTP (nginx)
resource "aws_security_group_rule" "ingress_chef_automate_allow_80_tcp" {
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = "${aws_security_group.chef_automate.id}"
}

# HTTPS (nginx)
resource "aws_security_group_rule" "ingress_chef_automate_allow_443_tcp" {
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = "${aws_security_group.chef_automate.id}"
}

# Allow etcd communication
resource "aws_security_group_rule" "ingress_chef_automate_allow_2379_tcp" {
  type                     = "ingress"
  from_port                = 2379
  to_port                  = 2380
  protocol                 = "tcp"
  security_group_id        = "${aws_security_group.chef_automate.id}"
  source_security_group_id = "${aws_security_group.chef_automate.id}"
}

# Allow elasticsearch clients
resource "aws_security_group_rule" "ingress_chef_automate_allow_9200_to_9400_tcp" {
  type                     = "ingress"
  from_port                = 9200
  to_port                  = 9400
  protocol                 = "tcp"
  security_group_id        = "${aws_security_group.chef_automate.id}"
  source_security_group_id = "${aws_security_group.chef_automate.id}"
}

# Allow postgres connections
resource "aws_security_group_rule" "ingress_chef_automate_allow_5432_tcp" {
  type                     = "ingress"
  from_port                = 5432
  to_port                  = 5432
  protocol                 = "tcp"
  security_group_id        = "${aws_security_group.chef_automate.id}"
  source_security_group_id = "${aws_security_group.chef_automate.id}"
}

# Allow leaderel connections
resource "aws_security_group_rule" "ingress_chef_automate_allow_7331_tcp" {
  type                     = "ingress"
  from_port                = 7331
  to_port                  = 7331
  protocol                 = "tcp"
  security_group_id        = "${aws_security_group.chef_automate.id}"
  source_security_group_id = "${aws_security_group.chef_automate.id}"
}

# Egress: ALL
resource "aws_security_group_rule" "linux_egress_allow_0-65535_all" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = "${aws_security_group.chef_automate.id}"
}

data "template_file" "install_chef_automate_cli" {
  template = "${file("${path.module}/templates/chef_automate/install_chef_automate_cli.sh.tpl")}"

  vars = {
    channel = "${var.channel}"
  }
}

resource "aws_instance" "chef_automate" {
  connection {
    user        = "${var.aws_ubuntu_image_user}"
    private_key = "${file("${var.aws_key_pair_file}")}"
    host = self.public_ip
  }

  ami                    = "${var.aws_ami_id == "" ? data.aws_ami.ubuntu.id : var.aws_ami_id}"
  instance_type          = "${var.automate_server_instance_type}"
  key_name               = "${var.aws_key_pair_name}"
  subnet_id              = "${aws_subnet.habmgmt-subnet-a.id}"
  vpc_security_group_ids = ["${aws_security_group.chef_automate.id}"]
  ebs_optimized          = true

  root_block_device {
    delete_on_termination = true
    volume_size           = 100
    volume_type           = "gp2"
  }

  tags = {
    Name          = "ccl-${terraform.workspace}-a2}"
    X-Dept        = "${var.tag_dept}"
    X-Customer    = "${var.tag_customer}"
    X-Project     = "${var.tag_project}"
    X-Application = "${var.tag_application}"
    X-Contact     = "${var.tag_contact}"
    X-TTL         = "${var.tag_ttl}"
  }

  provisioner "file" {
    destination = "/tmp/install_chef_automate_cli.sh"
    content     = "${data.template_file.install_chef_automate_cli.rendered}"
  }

  provisioner "file" {
    destination = "/tmp/ssl_cert"
    content = "${var.automate_custom_ssl_cert_chain}"
  }

  provisioner "file" {
    destination = "/tmp/ssl_key"
    content = "${var.automate_custom_ssl_private_key}"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo hostnamectl set-hostname ccl-${terraform.workspace}-a2.${var.automate_alb_r53_matcher}",
      "sudo sysctl -w vm.max_map_count=262144",
      "sudo sysctl -w vm.dirty_expire_centisecs=20000",
      "curl https://packages.chef.io/files/current/latest/chef-automate-cli/chef-automate_linux_amd64.zip |gunzip - > chef-automate && chmod +x chef-automate",
      "sudo chmod +x /tmp/install_chef_automate_cli.sh",
      "sudo bash /tmp/install_chef_automate_cli.sh",
      "sudo ./chef-automate init-config --file /tmp/config.toml $(if ${var.automate_custom_ssl}; then echo '--certificate /tmp/ssl_cert --private-key /tmp/ssl_key'; fi)",
      "sudo sed -i 's/fqdn = \".*\"/fqdn = \"ccl-${terraform.workspace}-a2.${var.automate_alb_r53_matcher}\"/g' /tmp/config.toml",
      "sudo sed -i 's/channel = \".*\"/channel = \"${var.channel}\"/g' /tmp/config.toml",
      "sudo sed -i 's/license = \".*\"/license = \"${var.automate_license}\"/g' /tmp/config.toml",
      "sudo rm -f /tmp/ssl_cert /tmp/ssl_key",
      "sudo mv /tmp/config.toml /etc/chef-automate/config.toml",
      "sudo ./chef-automate deploy /etc/chef-automate/config.toml --accept-terms-and-mlsa",
      "sudo chown ubuntu:ubuntu $HOME/automate-credentials.toml",
      "sudo echo -e \"api-token =\" $(sudo chef-automate admin-token) >> $HOME/automate-credentials.toml",
      "sudo cat $HOME/automate-credentials.toml",
    ]
  }

# "curl -X POST 'https://${var.automate_hostname}/api/v0/compliance/profiles?owner=admin' -H 'Content-Type: application/json' -H 'api-token: $(sudo chef-automate admin-token)' -d '{\"name\":\"stig-windowsserver2016-iii-administrativesensitive\",\"version\":\"1.0.0-10\"}'"

  provisioner "local-exec" {
    // Clean up local known_hosts in case we get a re-used public IP
    command = "ssh-keygen -R ${aws_instance.chef_automate.public_ip}"
  }

  provisioner "local-exec" {
    // Write ssh key for Automate server to local known_hosts so we can scp automate-credentials.toml in data.external.a2_secrets
    command = "ssh-keyscan -t ecdsa ${aws_instance.chef_automate.public_ip} >> ~/.ssh/known_hosts"
  }

}

data "external" "a2_secrets" {
  program = ["bash", "${path.module}/data-sources/get-automate-secrets.sh"]
  depends_on = ["aws_instance.chef_automate"]

  query = {
    ssh_user = "${var.platform}"
    ssh_key  = "${var.aws_key_pair_file}"
    a2_ip    = "${aws_instance.chef_automate.public_ip}"
  }
}
