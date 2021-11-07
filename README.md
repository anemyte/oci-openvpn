# Personal OpenVPN Server on Oracle Cloud Infrastructure

This is a simple [Terraform](https://www.terraform.io/) project that I started to learn the tool (Terraform). Exceptional performance, security, and/or reusability are outside of the scope of this project. It is meant to be as simple as possible way to create a personal VPN server using only OCI (Oracle Cloud Infrastructure) [always-free resources](https://www.oracle.com/cloud/free/#always-free). A free of charge personal VPN server, in other words.

The configuration consist of a server (obviously), a dedicated [VCN](https://docs.oracle.com/en-us/iaas/Content/Network/Concepts/overview.htm), a subnet, and a set of security rules to allow traffic to and from the server. 

# Usage

### Prerequisites

* [Terraform](https://learn.hashicorp.com/tutorials/terraform/install-cli?in=terraform/oci-get-started)
* [OCI CLI](https://docs.oracle.com/en-us/iaas/Content/API/Concepts/cliconcepts.htm)

### Create Server

1. Read [variables.tf](./variables.tf) to learn about possible configuration options.
1. Create file `terraform.tfvars` in this directory and use it to set values for the variables. At very least you have to provide a [compartment_id](https://docs.oracle.com/en-us/iaas/Content/General/Concepts/identifiers.htm):
    ```
    compartment_id     = "ocid1.tenancy.oc1..exampleocid"
    ```
1. Create infrastructure:
    ```bash
    terraform apply
    ```
    At the end of this command you will see the public IP address of the server. If you somehow missed it, you can get it with this command:
    ```bash
    terraform output ovpn_server_public_ip
    ```
    Use the address to connect to your server with SSH:
    ```bash
    ssh ubuntu@SERVER_IP
    ```
1. The server needs a couple of minutes after creation to install Docker on itself. You can watch the process by reading cloud-init log:
    ```bash
    sudo tail /var/log/cloud-init-output.log -f
    ```
    When the process is finished there should be lines like these:
    > Cloud-init v. 21.3-1-g6803368d-0ubuntu1~20.04.4 running 'modules:final' at Sun, 07 Nov 2021 09:41:18 +0000. Up 54.11 seconds.
    >
    > Cloud-init v. 21.3-1-g6803368d-0ubuntu1~20.04.4 finished at Sun, 07 Nov 2021 09:42:32 +0000. Datasource DataSourceOracle.  Up 128.02 seconds

1. Now you can start OpenVPN server. I recommend using [kylemanna/docker-openvpn](https://github.com/kylemanna/docker-openvpn) for the simplicity of usage. You may follow their [README](https://github.com/kylemanna/docker-openvpn/blob/master/README.md) to get things running or use the commands I use:
    ```bash
    OVPN_DATA=/home/ubuntu/ovpn
    IMAGE=kylemanna/openvpn:2.4@sha256:4de5e6690818c7c4025ae605369f681e813a7f9fe5d99feed988412c2d07987c
    SERVER_FQDN="$(curl ifconfig.me/ip)"

    # Init server config
    docker run --rm -v $OVPN_DATA:/etc/openvpn $IMAGE ovpn_genconfig -u "udp://$SERVER_FQDN"

    # Init PKI
    docker run --rm -it -v $OVPN_DATA:/etc/openvpn $IMAGE ovpn_initpki

    # Start the server
    docker run --name openvpn -d \
               -p 1194:1194/udp \
               --cap-add=NET_ADMIN \
               --restart unless-stopped \
               -v $OVPN_DATA:/etc/openvpn \
               $IMAGE

    # Create user configuration
    USERNAME=anemyte
    docker run -v $OVPN_DATA:/etc/openvpn --rm -it $IMAGE easyrsa build-client-full $USERNAME nopass

    # Export user configuration
    docker run -v $OVPN_DATA:/etc/openvpn --rm $IMAGE ovpn_getclient $USERNAME > $USERNAME.ovpn
    ```
    The exported config then can be used by an OpenVPN client to establish a VPN-tunnel to the server.
