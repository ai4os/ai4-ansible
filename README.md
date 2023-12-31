# Ansible roles for Consul, Nomad and Traefik automated deployment

These are the Ansible roles to manage the federated Nomad cluster in the AI4OS project.
The Ansible roles are valid to manage both iMagine and AI4EOSC sites.


## Ansible configuration

The machine running Ansible commands will be referred subsequently as **Ansible master**.

The ssh public key (`id_rsa.pub`) of the **Ansible master** must be added to every node
it manages (**Ansible slave**), inside `.ssh/authorized_keys`.

### Ansible hosts file

The default location for this file is `/etc/ansible/hosts`.
The file can also be specified at the command line using the `-i hosts` option when
executing.

```console
ansible-playbook -i hosts <playbook>
```

### SSH config file
This file configures a bastion node with a public IP which will be used as a proxy to
provide SSH access to the rest of the nodes in that subnet.

The bastion node will be the [server node](./docs/site_openstack.md#2-create-nodes)
of the new site, which will be used to connect to the client nodes of the new site
(which do not have public IP).

1. Copy [config_template](./config_template) into a config file with name `config`.
The location for this file must be the SSH folder (`.ssh/config`).

2. Modify the config file to match the cluster configuration.
   An example can be found on [config_example](./config_example).

   The following parameters must be set:
   - **bastion-name** is the name of the server node.
   - **bastion-public-ip** is the [public IP](./docs/site_openstack.md#3-associate-public-ips) associated to the server node.
   - **ssh-username** is the username of the server node's machine.
   If it was created with an Ubuntu flavour
   (see [Create nodes - step 3](./docs/site_openstack.md#2-create-nodes)),
   this username will be `ubuntu`.
   - **private-ips-on-bastion-subnet** are the set of private IPs of the client nodes.
   It can be configured as `<subnet>.*`, as in the example below.

   Template:
   ```
   Host <bastion-name>
      User <ssh-username>
      Hostname <bastion-public-ip>

   Host <private-ips-on-bastion-subnet>
      ProxyJump <bastion-name>
   ```

   Example:
   ```
   Host node-ifca-0
      User ubuntu
      Hostname 193.146.75.205

   Host 172.16.44.*
      ProxyJump node-ifca-0
   ```

## Usage

### IFCA admin

This use cases are aimed at IFCA admins.

#### Create federated cluster

To create a new federated cluster from scratch,
the IFCA admin must complete the following step:

- [Run Ansible to create the federated cluster](./docs/create_fed_cluster.md)


#### Add a new site to the federated cluster

To include a new site to the federated cluster,
the IFCA admin must complete the following steps:

- [Run Ansible to create the required certificates for the new site](./docs/ifca_ansible.md)
- [Configure your Openstack to integrate the new site](./docs/ifca_openstack.md)

### Site admin

To join the federated cluster with a new site,
the new site admin must complete the following steps:

- [Configure Openstack](./docs/site_openstack.md)
- [Run Ansible to join the federated cluster](./docs/site_ansible.md)

### Version update

To update Consul or Nomad versions on any nodes, the following step must be completed:

- [Run Ansible to update versions](./docs/update_versions.md)
