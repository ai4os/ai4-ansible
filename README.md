# Ansible roles for Consul, Nomad and Traefik automated deployment

These are the Ansible roles to manage the federated Nomad cluster in the AI4OS project.
The Ansible roles are valid to manage both iMagine and AI4EOSC sites.


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
This file configures a bastion node with a public IP which will be used as a proxy to provide SSH access to the rest of the nodes in that subnet .

> It must be modified to match the cluster configuration.
> Provided that each Nomad DC would be deployed on a different subnet, the following section must be replicated as many times as Nomad DCs.
<!-- todo: check susana -->
```
Host <bastion-name>
   User <ssh-username>
   Hostname <bastion-public-ip>

Host <private-ips-on-bastion-subnet>
   ProxyJump <bastion-name>

```

## Usage

### IFCA admin

If you are an IFCA admin willing to include a new site into the federated cluster,
you need to complete the following steps:

- [Run Ansible to create the required certificates for the new site](./docs/ifca_ansible.md)

### Site admin

If you are the admin of a new site willing to join to the cluster,
you need to complete the following steps:

- [Configure your Openstack](./docs/site_openstack.md)
- [Run Ansible to join the federated cluster](./docs/site_ansible.md)
