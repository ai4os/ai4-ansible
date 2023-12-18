# Ansible roles for Consul, Nomad and Traefik automated deployment

These are the Ansible roles to manage the federated Nomad cluster in the AI4OS project.
The Ansible roles are valid to manage both iMagine and AI4EOSC sites.

<!-- todo: add ifca host to gitignore -->


## Ansible configuration

The machine running Ansible commands will be referred subsequently as **Ansible master**.

The ssh public key (`id_rsa.pub`) of the **Ansible master** must be added to every node it manages (**Ansible slave**), inside `.ssh/authorized_keys`.

### Ansible hosts file

The default location for this file is `/etc/ansible/hosts`.
The file can also be specified at the command line using the `-i hosts` option when executing.

```console
ansible-playbook -i hosts <playbook>
```

### SSH config file

The default location for this file is `.ssh/config`.
This file configures a bastion node with a public IP which will be used as a proxy to
provide SSH access to the rest of the nodes in that subnet. 
The bastion node will be the server node of the new site ([Create nodes](/docs/site_openstack.md#2-create-nodes)),
which will be used to connect to the client nodes of the new site (which do not have public IP). 
Therefore:
- **bastion-name** is the name of the server node.
- **bastion-public-ip** is the public IP associated to the server node ([Associate public IPs](/docs/site_openstack.md#3-associate-public-ips)).
- **ssh-username** is the username of the server node's machine. If it was created with an Ubuntu flavour
following the recommendation ([Create nodes. Step 3](/docs/site_openstack.md#2-create-nodes)), this will be `ubuntu`.
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

If you are an IFCA admin willing to include a new site into the federated cluster,
you need to complete the following steps:

- [Run Ansible to create the required certificates for the new site](./docs/ifca_ansible.md)

<!-- add post actions - Openstack: add new site IPs to security groups  -->

### Site admin

If you are the admin of a new site willing to join to the cluster,
you need to complete the following steps:

- [Configure your Openstack](./docs/site_openstack.md)
- [Run Ansible to join the federated cluster](./docs/site_ansible.md)
