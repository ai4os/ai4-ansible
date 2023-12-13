# Ansible roles for Consul, Nomad and Traefik automated deployment

## Hosts configuration

### hosts file

The default location for this file is `/etc/ansible/hosts`.
The file can also be specified at the command line using the `-i hosts` option when executing. Example: `ansible-playbook -i hosts <playbook>`

### config file

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

### Ansible configuration
The ssh public key of the Ansible master must be added to every node it manages. 

Example: copy `./ssh/id_rsa.pub` from Ansible master to `.ssh/authorized_keys` on each Ansible slave.

---

## Use guide

### IFCA admin

- Follow `tutorials/new_site_ifca_admin.md` to create the ZIP file with required certificates for the new site.


### New site admin

- Follow `tutorials/new_site_guest_initial.md` to create the OpenStack new site.
- Follow `tutorials/new_site_guest_config.md` to join the federated cluster with the new site.



