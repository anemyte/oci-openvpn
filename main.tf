terraform {
  required_providers {
    oci = {
      source = "hashicorp/oci"
    }
  }
}

provider "oci" {
  region = var.region
  auth                = var.auth_type
  config_file_profile = var.oci_config_profile
}


resource "oci_core_instance" "ovpn_server" {

  display_name = "OpenVPN Server"
  shape        = var.instance_shape

  source_details {
    source_id   = data.oci_core_images.ubuntu_image.images[0].id
    source_type = "image"
  }

  metadata = {
    ssh_authorized_keys = file(pathexpand(var.path_to_ssh_public_key))
    user_data           = base64encode(file("./cloud-init.yaml"))
  }

  compartment_id      = var.compartment_id
  availability_domain = data.oci_identity_availability_domains.ads.availability_domains[0].name

  create_vnic_details {
    assign_public_ip = true
    subnet_id        = oci_core_subnet.main.id
    nsg_ids = [
      oci_core_network_security_group.default.id
    ]
  }
  preserve_boot_volume = false
}

output "ovpn_server_public_ip" {
  value = oci_core_instance.ovpn_server.public_ip
}


# Retrieve data for the server instance
data "oci_identity_availability_domains" "ads" {
  compartment_id = var.compartment_id
}

data "oci_core_images" "ubuntu_image" {
  compartment_id           = var.compartment_id
  operating_system         = "Canonical Ubuntu"
  operating_system_version = "20.04 Minimal"
}
