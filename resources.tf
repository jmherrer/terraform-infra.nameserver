data "vsphere_datacenter" "dc" {
  name = "SDDC-HomeLab"
}

data "vsphere_datastore" "datastore" {
  name          = "datastore-02"
  datacenter_id = "${data.vsphere_datacenter.dc.id}"
}

data "vsphere_compute_cluster" "cluster" {
  name          = "CL01"
  datacenter_id = "${data.vsphere_datacenter.dc.id}"
}

data "vsphere_network" "network" {
  name          = "LAN-LAB02"
  datacenter_id = "${data.vsphere_datacenter.dc.id}"
}

data "vsphere_virtual_machine" "template" {
  name          = "Templates/Ubuntu-160405-TPL"
  datacenter_id = "${data.vsphere_datacenter.dc.id}"
}

resource "vsphere_virtual_machine" "vm" {
  name             = "ns1"
  resource_pool_id = "${data.vsphere_compute_cluster.cluster.resource_pool_id}"
  datastore_id     = "${data.vsphere_datastore.datastore.id}"

  num_cpus = 1
  memory   = 512
  guest_id = "${data.vsphere_virtual_machine.template.guest_id}"

  scsi_type = "${data.vsphere_virtual_machine.template.scsi_type}"

  network_interface {
    network_id   = "${data.vsphere_network.network.id}"
    adapter_type = "${data.vsphere_virtual_machine.template.network_interface_types[0]}"
  }

  disk {
    label            = "disk0"
    size             = "${data.vsphere_virtual_machine.template.disks.0.size}"
    eagerly_scrub    = "${data.vsphere_virtual_machine.template.disks.0.eagerly_scrub}"
    thin_provisioned = "${data.vsphere_virtual_machine.template.disks.0.thin_provisioned}"
  }
  
  clone {
    template_uuid = "${data.vsphere_virtual_machine.template.id}"

    customize {
      linux_options {
        host_name = "ns1"
        domain    = "juanherreralab.net"
      }

      network_interface {
        ipv4_address = "10.100.20.25"
        ipv4_netmask = 24
      }

      ipv4_gateway = "10.100.20.1"
      dns_server_list = ["10.100.20.20"]
      dns_suffix_list = ["juanherreralab.net"]
    }
  }

  provisioner "file" {
      source = "conf/zones/db.juanherrera.com.ar"
      destination = "/home/ubuntu/db.juanherrera.com.ar"
       connection {
      type = "ssh"
      user = "${var.server_user}"
      password = "${var.server_password}"
    }
  }

    provisioner "file" {
      source = "conf/zones/db.200.125.124"
      destination = "/home/ubuntu/db.200.125.124"
       connection {
      type = "ssh"
      user = "${var.server_user}"
      password = "${var.server_password}"
    }
  }
  provisioner "file" {
    source = "conf/named.conf.local"
    destination = "/home/ubuntu/named.conf.local"
    connection {
      type = "ssh"
      user = "${var.server_user}"
      password = "${var.server_password}"
    }
  }
  provisioner "file" {
    source = "conf/named.conf.options"
    destination = "/home/ubuntu/named.conf.options"
    connection {
      type = "ssh"
      user = "${var.server_user}"
      password = "${var.server_password}"
    }
  }

  provisioner "remote-exec" {
    inline = [
      "echo ubuntu | sudo -S apt-get update",
      "sudo apt-get upgrade -y",
      "sudo apt-get install bind9 bind9utils bind9-doc -y",
      "echo '${var.PUBLIC_IP} ns1.juanherrera.com.ar ns1' | sudo tee -a /etc/hosts",
      "sudo mkdir -p /etc/bind/zones",
      "sudo rm /etc/bind/named.conf.options",
      "sudo rm /etc/bind/named.conf.local",
      "sudo mv /home/ubuntu/db.juanherrera.com.ar /etc/bind/zones",
      "sudo mv /home/ubuntu/db.200.125.124 /etc/bind/zones",
      "sudo mv /home/ubuntu/named.conf.local /etc/bind",
      "sudo mv /home/ubuntu/named.conf.options /etc/bind",
      "sudo service bind9 restart",
      "sudo ufw allow ssh",
      "sudo ufw allow 53",
      "sudo ufw --force enable"
    ]
    connection {
      type = "ssh"
      user = "${var.server_user}"
      password = "${var.server_password}"
    }
  }
}