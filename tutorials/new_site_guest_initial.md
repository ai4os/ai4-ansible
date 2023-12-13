# New site: guest admin prerequisites

This tutorial provides a guide to create an OpenStack site to later join the federated cluster.

## Create security groups

Create 4 security groups: *default*, *Consul*, *Nomad* an *Traefik*. To create each of them:

1. In section `Project > Network > Security groups`click `Create Security Group`
2. Set security group name and click `Create Security Group`.

Add rules to the security groups. To add them, simply click on the `Manage Rule` option of the security group and then `Add Rule`.

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

---

*<new_site_network>*: subnet of the new site. 

Example: 193.146.75.0/24.

*<traefik_node_public_IP>*: public IP assigned to the new site’s Traaefik node.

Example: 193.144.210.0.

---

## Create server node

1. Click `Launch instance` in section `Project > Compute > Instances`.
2. Set `Instance name` in section `Details`.
3. Select image source in section `Source`. It is recommended to be Ubuntu 22.04.
4. Select CPU flavour in section `Flavour`. It is recommended to be have a huge capacity. Example: a CPU flavour with 16 CPUs, 46 GB RAM, 40 GB SSD.
5. Select *default*, *Consul*, *Nomad* and *Traefik* security groups in section `Security Groups`.
6. Select key pair in section `Key Pair`.
7. Click `Launch instance`.

## Create Traefik node

Repite the same steps from [Create server node](https://www.notion.so/Create-server-node-a6a4ddcf706247f8bf7caa14b3ba3f41?pvs=21). 

In step 4, select a CPU flavour with low capacity. Example: a CPU flavour with 1 CPU,	2 GB RAM,	10 GB SSD.

## Create CPU client nodes

Repite the same steps from [Create server node](https://www.notion.so/Create-server-node-a6a4ddcf706247f8bf7caa14b3ba3f41?pvs=21) for each desired CPU client.

In step 4, select a CPU flavour with huge capacity. Example: a CPU flavour with 64 CPUs, 184 GB RAM, 100 GB SSD.

## Create GPU client nodes

Repite the same steps from [Create server node](https://www.notion.so/Create-server-node-a6a4ddcf706247f8bf7caa14b3ba3f41?pvs=21) for each desired GPU client.

In step 4, select a GPU flavour with huge capacity. Example: a GPU flavour with 86 CPUs, 8 GPUs, 351.6 GB RAM,	200 GB SSD.

## Add public IPs

Both server and Traefik node need a public IP each. For the rest of the nodes (CPU and GPU clients), it is not necessary.  

To associate a public IP to an instance:

1. In section `Project > Network > Floating IPs` select an available public IP address and click `Associate`.
2. In `Port to be associated`, select the port to the instace.
3. Click `Associate`.

## Add volumes

CPU and GPU client nodes are recommended to have an attached volume. For the rest of the nodes (server and Traefik), it is pointless.

To attach a volume to an instance:

1. In section `Project > Volumes > Volumes` select an available volume and click the down arrow (▼) next to the `Edit volume` option.
2. Click `Manage Attachments`.
3. In `Attach to Instance`, select the instace.
4. Click `Attach volume`.

---

After completing all steps for the new site creation, the configuration tutorial `tutorials/new_site_guest_config.md` can be followed to join the federated cluster.


