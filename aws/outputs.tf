output "chef_automate_public_ip" {
  value = "${aws_instance.chef_automate.public_ip}"
}

output "chef_automate_server_public_r53_dns" {
  value = "ccl-${terraform.workspace}-a2.${var.automate_alb_r53_matcher}"
}

output "a2_admin" {
  value = "${data.external.a2_secrets.result["a2_admin"]}"
}

output "a2_admin_password" {
  value = "${data.external.a2_secrets.result["a2_password"]}"
}

output "a2_token" {
  value = "${data.external.a2_secrets.result["a2_token"]}"
}

output "a2_url" {
  value = "${data.external.a2_secrets.result["a2_url"]}"
}

output "chef_node_public_ip" {
  value = "${aws_instance.aws-rhel7-node.*.public_ip}"
}
output "chef_node_public_dns" {
  value = "${aws_instance.aws-rhel7-node.*.public_dns}"
}

output "chef_workstation_public_ip" {
  value = "${aws_instance.aws-centos7-workstation.*.public_ip}"
}
output "chef_workstation_public_dns" {
  value = "${aws_instance.aws-centos7-workstation.*.public_dns}"
}

output "student_workstation_public_dns" {
  value = "${aws_route53_record.centos-wks.fqdn}"
}

output "student_node_public_dns" {
  value = "${aws_route53_record.rhel7-node.*.fqdn}"
}
