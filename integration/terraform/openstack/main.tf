locals {
  username     = "rik"
  cluster_name = "rik-${var.cluster_name}"
  os           = "debian-cloud/debian-11"
}

# Create the private key which will be
# used to access our cluster nodes
resource "tls_private_key" "ssh" {
  algorithm = "RSA"
  rsa_bits  = 8192
}

# Creates the compute network on openstack
resource "openstack_networking_network_v2" "rik" {
  name           = "${local.cluster_name}-vpc"
}

# Create the master static ip
resource "openstack_compute_floatingip_v2" "master_static" {
  pool = var.ip_pool
}

# Create the worker static ip
resource "openstack_compute_floatingip_v2" "worker_static" {
  count = var.workers_count
  pool = var.ip_pool
}

# Authorize SSH
resource "openstack_networking_secgroup_v2" "rik_master" {
  name        = "${local.cluster_name}-secgroup-master"
  description = "Security group for ${local.cluster_name}"
}

resource "openstack_networking_secgroup_v2" "rik_worker" {
  name        = "${local.cluster_name}-secgroup-worker"
  description = "Security group for ${local.cluster_name}"
}

resource "openstack_networking_secgroup_rule_v2" "ssh" {
  direction         = "ingress"
  ethertype         = "IPv4"
  port_range_max    = 22
  port_range_min    = 22
  protocol          = "tcp"
  remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = openstack_networking_secgroup_v2.rik_master.id
}

resource "openstack_networking_secgroup_rule_v2" "ssh2" {
  direction         = "ingress"
  ethertype         = "IPv4"
  port_range_max    = 22
  port_range_min    = 22
  protocol          = "tcp"
  remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = openstack_networking_secgroup_v2.rik_worker.id
}

# Authorize external access to the RIK API
resource "openstack_networking_secgroup_rule_v2" "api_server" {
  direction         = "ingress"
  ethertype         = "IPv4"
  port_range_max    = 5000
  port_range_min    = 5000
  protocol          = "tcp"
  remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = openstack_networking_secgroup_v2.rik_master.id
}

# Authorize external access to the RIK API on openstack
resource "openstack_networking_secgroup_rule_v2" "workers" {
  direction         = "ingress"
  ethertype         = "IPv4"
  port_range_max    = 4995
  port_range_min    = 4995
  protocol          = "tcp"
  remote_ip_prefix  = "${openstack_compute_floatingip_v2.worker_static[0].address}/32"
  security_group_id = openstack_networking_secgroup_v2.rik_worker.id
}



/*
# Creates the rik master node

resource "google_compute_instance" "master" {
  name         = "${local.cluster_name}-master"
  machine_type = "e2-micro"
  zone         = "europe-west1-b"

  # Add the generated SSH key to the instance
  # So we can use SSH provisioner to copy files & configure the instance
  metadata = {
    ssh-keys = "${local.username}:${tls_private_key.ssh.public_key_openssh}"
  }

  network_interface {
    network = google_compute_network.rik.name
    access_config {
      nat_ip = google_compute_address.master_static.address
    }
  }

  boot_disk {
    initialize_params {
      image = local.os
    }
  }

  connection {
    type        = "ssh"
    user        = local.username
    host        = google_compute_address.master_static.address
    private_key = tls_private_key.ssh.private_key_pem
  }

  provisioner "file" {
    source      = "${path.root}/../../../target/debian/controller_1.0.0_amd64.deb"
    destination = "/tmp/controller.deb"
  }

  provisioner "file" {
    source      = "${path.root}/../../../target/debian/scheduler_1.0.0_amd64.deb"
    destination = "/tmp/scheduler.deb"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo dpkg -i /tmp/scheduler.deb",
      "sudo dpkg -i /tmp/controller.deb",
      "sudo systemctl start scheduler.service",
      "sudo systemctl start rik-controller.service"
    ]
  }
}





# Creates the workers instances
resource "google_compute_instance" "worker" {
  count        = var.workers_count
  name         = "${local.cluster_name}-worker-${count.index}"
  machine_type = "e2-micro"
  zone         = "europe-west1-b"

  # Add the generated SSH key to the instance
  # So we can use SSH provisioner to copy files & configure the instance
  metadata = {
    ssh-keys = "${local.username}:${tls_private_key.ssh.public_key_openssh}"
  }

  network_interface {
    network = google_compute_network.rik.name
    access_config {
      nat_ip = google_compute_address.worker_static[count.index].address
    }
  }

  boot_disk {
    initialize_params {
      image = local.os
    }
  }

  connection {
    type        = "ssh"
    user        = local.username
    host        = google_compute_address.worker_static[count.index].address
    private_key = tls_private_key.ssh.private_key_pem
  }

  provisioner "file" {
    source      = "${path.root}/../../../target/debian/riklet_1.0.0_amd64.deb"
    destination = "/tmp/riklet.deb"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo apt-get update",
      "sudo apt-get install -y runc skopeo umoci",
      "sudo dpkg -i /tmp/riklet.deb",
      "echo 'ARG1=--master-ip ${google_compute_address.master_static.address}:4995' >> /tmp/.rikletconf",
      "echo 'ARG2=-v' >> /tmp/.rikletconf",
      "sudo systemctl start riklet.service"
    ]
  }
}
*/
