# This one is the only mandatory. It defines where (in which compartment) all objects are created.
variable "compartment_id" {
  description = "OCID from your tenancy page. From your user avatar, go to Tenancy: <your-tenancy> and copy OCID."
  type        = string
}

# Just as compartment_id this defines where the resources will be created, only this time 'where'
# means geographical location (datacenter).
variable "region" {
  description = "region where you have OCI tenancy"
  type        = string
  default     = "eu-amsterdam-1"
}

# How Terraform should authenticate to OCI.
variable "auth_type" {
  description = "The type of auth to use. Options are 'ApiKey', 'SecurityToken' and 'InstancePrincipal'"
  type        = string
  default     = "SecurityToken"
}

# The name of the OCI config profile.
variable "oci_config_profile" {
  description = "The profile name to be used from OCI CLI config file."
  type        = string
  default     = "DEFAULT"
}

# Defines specs (CPU, RAM) of the server. At the moment of writing Oracle offered
# two VM.Standard.E2.1.Micro on always-free basis.
variable "instance_shape" {
  description = "The shape (type) of instance to create."
  type        = string
  default     = "VM.Standard.E2.1.Micro"
}

variable "path_to_ssh_public_key" {
  description = "Path to your public SSH-key, usually /home/username/.ssh/id_rsa.pub"
  type        = string
  default     = "~/.ssh/id_rsa.pub"
  validation {
    condition = fileexists(pathexpand(var.path_to_ssh_public_key))
    error_message = "Provide path for SSH public key that you will use to connect to the server."
  }
}

# These two are used to configure firewall to allow incoming "listen_protocol" 
# connections to "listen_port".
variable "listen_protocol" {
  description = "The protocol (TCP|UDP) the server will listen on."
  type        = string
  default     = "UDP"
  validation {
    condition     = upper(var.listen_protocol) == "TCP" || upper(var.listen_protocol) == "UDP"
    error_message = "The listen_protocol must be either TCP or UDP."
  }
}
variable "listen_port" {
  description = "The port number the server will listen on."
  type        = number
  default     = 1194
}
