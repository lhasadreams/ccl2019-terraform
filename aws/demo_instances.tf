resource "aws_instance" "aws-rhel7-node" {
  connection {
    user        = "ec2-user"
    private_key = "${file("${var.aws_key_pair_file}")}"
  }

  count         = "${var.linux_node_instance_count}"
  ami                         = "${data.aws_ami.rhel7.id}"
  instance_type               = "t2.micro"
  key_name                    = "${var.aws_key_pair_name}"
  subnet_id                   = "${aws_subnet.habmgmt-subnet-a.id}"
  vpc_security_group_ids      = ["${aws_security_group.chef_automate.id}"]
  associate_public_ip_address = true

  depends_on = ["aws_instance.chef_automate"]

  tags {
    Name          = "aws_rhel7_production_${random_id.instance_id.hex}_Lin_${count.index + 1}"
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
    destination = "/home/ec2-user/hab-sup.service"
  }

  provisioner "file" {
    content     = "${data.template_file.linux_baseline.rendered}"
    destination = "/home/ec2-user/linux_baseline.toml"
  }

  provisioner "file" {
    content     = "${data.template_file.chef-base.rendered}"
    destination = "/home/ec2-user/chef-base.toml"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo rm -rf /etc/machine-id",
      "sudo systemd-machine-id-setup",
      "sudo hostname aws-rhel7",
      "sudo groupadd hab",
      "sudo adduser hab -g hab",
      "chmod +x /tmp/install_hab.sh",
      "sudo /tmp/install_hab.sh",
      "sudo hab license accept",
      "sudo mv /home/ec2-user/hab-sup.service /etc/systemd/system/hab-sup.service",
      "sudo systemctl daemon-reload",
      "sudo systemctl start hab-sup",
      "sudo systemctl enable hab-sup",
      "sleep 60",
    ]
  }
}

////////////////////////////////
// Template

data "template_file" "sup_service" {
  template = "${file("${path.module}/templates/hab-sup.service")}"

  vars {
    flags = "--auto-update --listen-gossip 0.0.0.0:9638 --listen-http 0.0.0.0:9631"
  }
}

data "template_file" "install_hab" {
  template = "${file("${path.module}/templates/install-hab.sh")}"
}

data "template_file" "linux_baseline" {
  template = "${file("${path.module}/templates/chef_nodes/linux_baseline.tpl")}"

  vars {
    url = "${data.external.a2_secrets.result["a2_url"]}/data-collector/v0"
    token = "${data.external.a2_secrets.result["a2_token"]}"
    verify_ssl = "${var.verify_ssl}"
    server = "${data.external.a2_secrets.result["a2_url"]}"
  }
}

data "template_file" "chef-base" {
  template = "${file("${path.module}/templates/chef_nodes/chef-base.tpl")}"

  vars {
    server_url = "${data.external.a2_secrets.result["a2_url"]}/data-collector/v0"
    token = "${data.external.a2_secrets.result["a2_token"]}"
  }
}

