# New site: Openstack configuration

This tutorial provides a guide to create an OpenStack site.

Once this tutorials is completed:
- IFCA admins can proceed with [Running Ansible to create the federated cluster](./create_fed_cluster.md).
- New site admin can proceed with [Running Ansible to join the federated cluster](./site_ansible.md).


## 1. Create security groups

You need to create 5 security groups: *default*, *Consul*, *Nomad*, *Traefik* and *Federation*.
To create each one of them:

1. In section `Project > Network > Security Groups`, click `Create Security Group`.
2. Set security group name and click `Create Security Group`.

Then, add rules to the security groups. To add them, simply click on the `Manage Rule`
option of the security group and then `Add Rule`.

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
| Ingress | IPv4 | TCP | 8002-8003 | 0.0.0.0/0 | NVFLARE |
| Ingress | IPv4 | TCP | 8081 | <new_site_network> | Traefik dashboard |

- Federation

| Direction | Ether Type | IP Protocol | Port Range | Remote IP Prefix | Description |
| --- | --- | --- | --- | --- | --- |
| Ingress | IPv4 | TCP | Any | <fed_site_1_network> | <Name of the federated site 1> subnet |
...
| Ingress | IPv4 | TCP | Any | <fed_site_n_network> | <Name of the federated site N> subnet |


where:

* `<new_site_network>` is subnet of the new site (eg. `193.146.75.0/24`).
* `<traefik_node_public_IP>` is the public IP assigned to the new site’s Traefik node
  (eg. `193.144.210.0`).
* `<fed_site_i_network>`is the subnetof the ith site in the federated cluster. The list of all sites with their subnets must be provided from the IFCA admin.


## 2. Create nodes

> ⓘ  **Tip** \
> We recommend having a _few big nodes_ instead of a lot of small ones,
> because this leads to:
> * better resource utilization: no duplicated user docker images between nodes,
> less node resources remainders that are not able to fill a full job, etc
> * better node management: you need to apply Ansible in fewer nodes.
>
> But this of course depends on your available flavors.


To create a node in OpenstacK:

1. Click `Launch Instance` in section `Project > Compute > Instances`.
2. Set `Instance Name` in section `Details`.
   > ⚠  Nodes must **not** use hyphens `-` in their name.
   > Instead, they may use underscores `_`.
3. Select image source in section `Source`. We recommend Ubuntu 22.04.
4. Select CPU flavour in section `Flavour`, where hardware requirements are based on the
 tentative node specs listed below.
5. Select *default*, *Consul*, *Nomad* and *Traefik* security groups in section `Security Groups`.
6. Select key pair in section `Key Pair`.
7. Click `Launch Instance`.

You should create the following nodes:

* 1 server node: \
  Tentative specs: `16 CPUs, 46 GB RAM, 40 GB SSD`
* 1 Traefik node: \
  Tentative specs: `1 CPU, 2 GB RAM, 10 GB SSD`
* $N$ CPU client nodes ($N \geqslant 0 $): \
  Tentative specs: `64 CPUs, 184 GB RAM, 100 GB SSD`
* $N$ GPU client nodes ($N \geqslant 0 $): \
  Tentative specs: `86 CPUs, 8 GPUs, 351.6 GB RAM, 200 GB SSD`

Once the nodes are created, the [Ansible configuration](../README.md#ansible-configuration) must be followed to:
- Add the Ansible master SSH key to every node.
- Complete the [SSH configuration](../README.md#ssh-config-file).


## 3. Associate public IPs

Both server and Traefik node need a public IP each.
For the rest of the nodes (CPU and GPU clients), it is not necessary.

To associate a public IP to an instance:

1. In section `Project > Network > Floating IPs`, select an available public IP address
  and click `Associate`.
2. In `Port to be associated`, select the port to the instance.
3. Click `Associate`.


## 4. Create and attach volumes

CPU and GPU client compute nodes **must** have an attached volume.
Server and Traefik nodes do not need attached volumes.

The reason is that Nomad jobs need to use the docker
[storage-opt](https://docs.docker.com/engine/reference/commandline/dockerd/#overlay2size)
option to limit the disk in containers. An because Docker is using the
Overlay storage driver, the filesystem has to be `xfs`.
Ansible will configure that volume with xfs and make Docker run in it.

Volumes are also needed because otherwise nodes would fill up quite quickly with
Docker images (which in the current cluster add up to 70GB in some nodes)
and in addition, we wouldn't be able to offer users enough space to copy their dataset
to the deployments.

To create a volume:

1. In section `Project > Volumes > Volumes`, select `Create Volume`.
2. Set volume name in `Volume Name`.
3. Set volume size in `Volume Size (GiB)`.
4. Click `Create Volume`.

To attach a volume to an instance:

1. In section `Project > Volumes > Volumes`, select an available volume and click the
  down arrow (▼) next to the `Edit Volume` option.
2. Click `Manage Attachments`.
3. In `Attach to Instance`, select the instance.
4. Click `Attach Volume`.

We recommend that:
* **CPU nodes** have volumes with _at least_ 5 GB per CPU core.
  As a reference, IFCA cluster has 15 GB per CPU core.
* **GPU nodes** have volumes with _at least_ 50 GB per GPU device.
  As a reference, IFCA cluster has 250 GB per GPU device.
