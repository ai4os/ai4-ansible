# Ansible roles for Consul, Nomad and Traefik automated deployment

## Hosts configuration

### [hosts](https://github.com/ai4os/ai4-ansible/blob/2024391a30a913ba1829369a56e6f3708ffac261/hosts) file

The default location for this file is `/etc/ansible/hosts`.
The file can also be specified at the command line using the `-i hosts` option when executing. Example: `ansible-playbook -i hosts <playbook>`

### [config](https://github.com/ai4os/ai4-ansible/blob/2024391a30a913ba1829369a56e6f3708ffac261/config) file

The default location for this file is `.ssh/config`.
This file configures a bastion node with a public IP which will be used as a proxy to provide SSH access to the rest of the nodes in that subnet .

> It must be modified to match the cluster configuration.
Provided that each Nomad DC would be deployed on a different subnet, the following section must be replicated as many times as Nomad DCs.
> 

```
Host <bastion-name>
   User <ssh-username>
   Hostname <bastion-public-ip>

Host <private-ips-on-bastion-subnet>
   ProxyJump <bastion-name>

```

## Execution instructions

### 1. Consul

- Configure Consul new agents on the [hosts](https://github.com/ai4os/ai4-ansible/blob/2024391a30a913ba1829369a56e6f3708ffac261/hosts) file.
    
    **ansible_host**: IP of the machine (use public when available)
    
    Example: `<host_name> ansible_host=<public_IP>`
    
- Define Consul variables on [group_vars/all.yml](https://github.com/ai4os/ai4-ansible/blob/2024391a30a913ba1829369a56e6f3708ffac261/group_vars/all.yml) if desired. It is recommended to use default variables.
- Execute `ansible-playbook playbook-join-consul.yaml` to deploy the Consul DC.

### 2. Nomad

- Configure Nomad new agents on the [hosts](https://github.com/ai4os/ai4-ansible/blob/2024391a30a913ba1829369a56e6f3708ffac261/hosts) file.
    
    **nomad_dc**: Nomad datacenter
    
    **domain**: Nomad domain
    
    **nomad_namespaces**: List of Nomad namespaces
    
    Example: `<host_name> nomad_dc=<nomad_dc_name> domain=<nomad_domain> nomad_namespaces=<namespace1,namespace2>`
    
- Define Nomad variables on [group_vars/all.yml](https://github.com/ai4os/ai4-ansible/blob/2024391a30a913ba1829369a56e6f3708ffac261/group_vars/all.yml) if desired. It is recommended to use default variables.
- Execute `ansible-playbook playbook-join-nomad.yaml` to deploy all Nomad DCs.

### 3. Traefik and Volumes

- Configure Traefik master on the [hosts](https://github.com/ai4os/ai4-ansible/blob/2024391a30a913ba1829369a56e6f3708ffac261/hosts) file.
- Configure Nomad clients with attached volumes on the [hosts](https://github.com/ai4os/ai4-ansible/blob/2024391a30a913ba1829369a56e6f3708ffac261/hosts) file.
    
    **vol_name**: Volume name
    
    **partition_name**: Name for the partition
    
    Example: `<host_name> vol_name=<volume_name> partition_name=<name_for_partition>`
    
- Execute `ansible-playbook playbook-join-traefik.yaml` to deploy the Traefik service and configure Nomad clients with volumes.
