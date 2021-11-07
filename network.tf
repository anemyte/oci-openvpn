# Create a dedicated VCN
resource "oci_core_vcn" "default" {
  cidr_block     = "172.16.0.0/20"
  compartment_id = var.compartment_id
  display_name   = "OpenVPN VCN"
}

# Create a subnet in the VCN
resource "oci_core_subnet" "main" {
  vcn_id                     = oci_core_vcn.default.id
  cidr_block                 = "172.16.0.0/24"
  compartment_id             = var.compartment_id
  display_name               = "OpenVPN Main Subnet"
  prohibit_public_ip_on_vnic = false
}

# Create a default internet gateway for the VCN
resource "oci_core_internet_gateway" "default" {
  compartment_id = var.compartment_id
  vcn_id         = oci_core_vcn.default.id
  display_name   = "Default Gateway"
  enabled        = true
}

# Create a default route to the internet
resource "oci_core_default_route_table" "default" {
  manage_default_resource_id = oci_core_vcn.default.default_route_table_id
  route_rules {
    description       = "Default route to the internet."
    network_entity_id = oci_core_internet_gateway.default.id
    destination       = "0.0.0.0/0"
    destination_type  = "CIDR_BLOCK"
  }
}

# Create a security group and add rules to it
resource "oci_core_network_security_group" "default" {
  display_name   = "OpenVPN Default"
  compartment_id = var.compartment_id
  vcn_id         = oci_core_vcn.default.id
}

resource "oci_core_network_security_group_security_rule" "allow_openvpn" {
  network_security_group_id = oci_core_network_security_group.default.id
  direction                 = "INGRESS"
  protocol                  = upper(var.listen_protocol) == "TCP" ? "6" : "17" # "6" is TCP, "17" is UDP
  stateless                 = true

  description = "Allow OpenVPN."
  source      = "0.0.0.0/0"
  source_type = "CIDR_BLOCK"

  # This block only appears if var.listen_protocol == "TCP"
  dynamic "tcp_options" {
    for_each = upper(var.listen_protocol) == "TCP" ? [1] : []
    content {
      destination_port_range {
        min = var.listen_port
        max = var.listen_port
      }
    }

  }
  # This block only appears if var.listen_protocol == "UDP"
  dynamic "udp_options" {
    for_each = upper(var.listen_protocol) == "UDP" ? [1] : []
    content {
      destination_port_range {
        min = var.listen_port
        max = var.listen_port
      }
    }

  }
}

resource "oci_core_network_security_group_security_rule" "allow_ssh" {
  network_security_group_id = oci_core_network_security_group.default.id
  direction                 = "INGRESS"
  protocol                  = "6"
  stateless                 = true

  description = "Allow SSH connections."
  source      = "0.0.0.0/0"
  source_type = "CIDR_BLOCK"
  tcp_options {
    destination_port_range {
      max = "22"
      min = "22"
    }
  }
}

resource "oci_core_network_security_group_security_rule" "allow_mtu_discovery" {
  network_security_group_id = oci_core_network_security_group.default.id
  direction                 = "INGRESS"
  protocol                  = "1"
  stateless                 = true

  description = "Allow MTU Discovery."
  source      = "0.0.0.0/0"
  source_type = "CIDR_BLOCK"
  icmp_options {
    type = 3
    code = 4
  }
}

resource "oci_core_network_security_group_security_rule" "allow_ping" {
  network_security_group_id = oci_core_network_security_group.default.id
  direction                 = "INGRESS"
  protocol                  = "1"
  stateless                 = true

  description = "Allow Ping."
  source      = "0.0.0.0/0"
  source_type = "CIDR_BLOCK"
  icmp_options {
    type = 8
    code = 0
  }
}

resource "oci_core_network_security_group_security_rule" "allow_all_outbound" {
  network_security_group_id = oci_core_network_security_group.default.id
  direction                 = "EGRESS"
  protocol                  = "all"

  description      = "Allow everything."
  destination      = "0.0.0.0/0"
  destination_type = "CIDR_BLOCK"
}

