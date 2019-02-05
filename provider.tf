provider "vsphere" {
  user           = "${var.vcenter_user}"
  password       = "${var.vcenter_password}"
  vsphere_server = "labs1001.juanherreralab.net"

  # If you have a self-signed cert
  allow_unverified_ssl = true
}