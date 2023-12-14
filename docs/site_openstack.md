# New site: Openstack configuration

This tutorial provides a guide to create an OpenStack site to later join the federated cluster.

Once this tutorials is completed you can proceed with
[Running Ansible to join the federated cluster](./site_ansible.md)

## 1. Create security groups

You need to create 4 security groups: *default*, *Consul*, *Nomad* an *Traefik*.
To create each one of them:

1. In section `Project > Network > Security groups` click `Create Security Group`
2. Set security group name and click `Create Security Group`.

Then add rules to the security groups. To add them, simply click on the `Manage Rule` option of the security group and then `Add Rule`.

<!-- todo: Susana needs to check these rules with Álvaro -->

The needed rules for each group are:

- default

| Direction | Ether Type | IP Protocol | Port Range | Remote IP Prefix | Description |
| --- | --- | --- | --- | --- | --- |
| Egress | IPv4 | Any | Any | 0.0.0.0/0 | - |
| Egress | IPv6 | Any | Any | ::/0 | - |
| Ingress | IPv4 | ICMP | Any | 0.0.0.0/0 | - |
| Ingress | IPv4 | TCP | Any | - | default |
| Ingress | IPv4 | TCP | 22 (SSH) | 0.0.0.0/0 | - |
| Ingress | IPv4 | UDP | Any | - | default |
| Ingress | IPv6 | TCP | Any | - | default |
| Ingress | IPv6 | UDP | Any | - | default |

- Consul

| Direction | Ether Type | IP Protocol | Port Range | Remote IP Prefix | Description |
| --- | --- | --- | --- | --- | --- |
| Egress | IPv4 | Any | Any | 0.0.0.0/0 | - |
| Egress | IPv6 | Any | Any | ::/0 | - |
| Ingress | IPv4 | TCP | 8300 | <new_site_network> | Consul server |
| Ingress | IPv4 | TCP | 8301 | <new_site_network> | LAN Serf |
| Ingress | IPv4 | TCP | 8302 | <new_site_network> | WAN Serf |
| Ingress | IPv4 | TCP | 8500 | <new_site_network> | Consul HTTP |
| Ingress | IPv4 | TCP | 8501 | <new_site_network> | Consul HTTPs |
| Ingress | IPv4 | TCP | 8502 | <new_site_network> | Consul gRPC |
| Ingress | IPv4 | TCP | 8503 | <new_site_network> | Consul gRPC (TLS) |
| Ingress | IPv4 | TCP | 8600 | <new_site_network> | Consul DNS server (TCP and UDP) |
| Ingress | IPv4 | TCP | 21000 - 21255 | - | Sidecar proxies |
| Ingress | IPv4 | UDP | 8301 | <new_site_network> | LAN Serf |
| Ingress | IPv4 | UDP | 8302 | <new_site_network> | WAN Serf |
| Ingress | IPv4 | UDP | 8600 | <new_site_network> | Consul DNS server (TCP and UDP) |

- Nomad

| Direction | Ether Type | IP Protocol | Port Range | Remote IP Prefix | Description |
| --- | --- | --- | --- | --- | --- |
| Egress | IPv4 | Any | Any | 0.0.0.0/0 |  |
| Egress | IPv6 | Any | Any | ::/0 |  |
| Ingress | IPv4 | TCP | 4646 | 0.0.0.0/0 | Nomad HTTP API |
| Ingress | IPv4 | TCP | 4646 | <new_site_network> | Nomad HTTP API |
| Ingress | IPv4 | TCP | 4647 | <new_site_network> | Nomad RPC |
| Ingress | IPv4 | TCP | 4648 | <new_site_network> | Nomad Serf WAN |
| Ingress | IPv4 | UDP | 4648 | <new_site_network> | Nomad Serf WAN |

- Traefik

| Direction | Ether Type | IP Protocol | Port Range | Remote IP Prefix | Description |
| --- | --- | --- | --- | --- | --- |
| Egress | IPv4 | Any | Any | 0.0.0.0/0 |  |
| Egress | IPv6 | Any | Any | ::/0 |  |
| Ingress | IPv4 | TCP | 80 (HTTP) | 0.0.0.0/0 |  |
| Ingress | IPv4 | TCP | 443 (HTTPS) | 0.0.0.0/0 | Allow SSL |
| Ingress | IPv4 | TCP | 8081 | <new_site_network> | Traefik dashboard |
| Ingress | IPv4 | TCP | 8081 | <traefik_node_public_IP>/24 | Traefik dashboard |

where:

* `<new_site_network>` is subnet of the new site (eg. `193.146.75.0/24`)`.
* `<traefik_node_public_IP>` is the public IP assigned to the new site’s Traefik node
  (eg. `193.144.210.0`)`.

## 2. Create nodes

To create a node in OpenstacK:

1. Click `Launch instance` in section `Project > Compute > Instances`.
2. Set `Instance name` in section `Details`.
3. Select image source in section `Source`. We recommend Ubuntu 22.04.
4. Select CPU flavour in section `Flavour`, were based on the required node specs.
5. Select *default*, *Consul*, *Nomad* and *Traefik* security groups in section `Security Groups`.
6. Select key pair in section `Key Pair`.
7. Click `Launch instance`.

You should create the following nodes:

* 1 server node: \
  Tentative specs: `16 CPUs, 46 GB RAM, 40 GB SSD`
* 1 Traefik node: \
  Tentative specs: `1 CPU, 2 GB RAM, 10 GB SSD`
* $N$ CPU client nodes ($N \geqslant 0 $): \
  Tentative specs: `64 CPUs, 184 GB RAM, 100 GB SSD`
* $N$ GPU client nodes ($N \geqslant 0 $): \
  Tentative specs: `86 CPUs, 8 GPUs, 351.6 GB RAM, 200 GB SSD`

<!-- todo: add Ansible master ssh key in every node? -->

## 3. Attach public IPs

Both server and Traefik node need a public IP each.
For the rest of the nodes (CPU and GPU clients), it is not necessary.

To associate a public IP to an instance:

1. In section `Project > Network > Floating IPs` select an available public IP address and click `Associate`.
2. In `Port to be associated`, select the port to the instance.
3. Click `Associate`.

## 4. Create and attach volumes

CPU and GPU client nodes are recommended to have an attached volume.

Server and Traefik nodes do not need attached volumes.

<!-- todo: how to create a volume -->

To attach a volume to an instance:

1. In section `Project > Volumes > Volumes` select an available volume and click the down arrow (▼) next to the `Edit volume` option.
2. Click `Manage Attachments`.
3. In `Attach to Instance`, select the instance.
4. Click `Attach volume`.

<!-- todo: fix these numbers -->
We recommend that:
* **CPU nodes** have volumes with _at least_ 10 GB per CPU core.
* **GPU nodes** have volumes with _at least_ 50 GB per GPU.
