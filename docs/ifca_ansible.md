# IFCA admin: Ansible deployment

To add a new site to the federated cluster, an **IFCA admin** should follow the
following steps from the [Ansible master](../README.md#ansible-configuration)
to generate certs.

> ⚠  **Requirements** \
> Before starting this tutorial, the IFCA admin must **receive the hosts file**
> from the new site admin.


## 1. Configure hosts

Copy [hosts_ifca_admin_template](../hosts_ifca_admin_template) into a new hosts file
(e.g. `myhosts`).

Modify the new hosts file to match the new cluster configuration reflected in the
_received_ hosts file from the new site admin.
An example can be found on [hosts_ifca_admin_example](../hosts_ifca_admin_example).
Specifically, modify the following groups:

- **consul_master**

    Modify the line to match the IFCA Consul master name and its public IP.

    > ⚠ There should only be one Consul master, which matches with the Consul server.

    Line template:
    ```ini
    <ifca_consul_master_node> ansible_host=<ifca_consul_master_public_ip>
    ```

    Group example:
    ```ini
    [consul_master]
    node-ifca-0 ansible_host=193.146.75.205
    ```

- **consul_new_servers**

    Modify the line to match the new Consul server name and its public IP.

    > ⚠ There should only be one Consul server.

    Line template:
    ```ini
    <new_server_name> ansible_host=<new_server_public_IP>
    ```

    Group example:
    ```ini
    [consul_new_servers]
    new-server ansible_host=193.146.75.194
    ```

- **consul_new_clients**

    Modify the lines to match the new Consul client names and its IPs.

    > ⚠ The Traefik node must always have public IP.
    > For the rest of the clients, public IPs are optional.

    Line template:
    ```ini
    <new_client_name> ansible_host=<new_client_IP>
    ```

    Group example:
    ```ini
    [consul_new_clients]
    new-traefik ansible_host=193.146.75.162
    new-cpu-client ansible_host=172.16.43.137
    new-gpu-client ansible_host=172.16.43.58
    ```

- **traefik_new_master**

    Modify the line to match the new Traefik name.

    > ⚠ There should only be one Traefik instance.

    Line template:
    ```ini
    <new_traefik_name>
    ```

    Group example:
    ```ini
    [traefik_new_master]
    new-traefik
    ```

- **nomad_new_servers**

    Modify the line to match the new Nomad server name.

    > ⚠ There should only be one Nomad server.

    Line template:
    ```ini
    <new_server_name>
    ```

    Group example:
    ```ini
    [nomad_new_servers]
    new-server
    ```

- **nomad_new_cpu_clients**

    Modify the lines to match the new Nomad CPU client names.

    > ⓘ CPU clients are Nomad clients without GPU. The Traefik node should also be
    > included in this group.

    > ⚠ There should always be at least 1 CPU client; the Traefik node.

    Line template:
    ```ini
    <new_cpu_client_name>
    ```

    Group example:
    ```ini
    [nomad_new_cpu_clients]
    new-traefik
    new-cpu-client
    ```

- **nomad_new_gpu_clients**

    Modify the lines to match the new Nomad GPU client names.

    > ⚠ If there are no GPU clients, leave the group empty (**do not delete the group**).

    Line template:
    ```ini
    <new_gpu_client_name>
    ```

    Group example:
    ```ini
    [nomad_new_gpu_clients]
    new-gpu-client
    ```


## 2. Modify group_vars

Modify [group_vars/all.yml](../group_vars/all.yml) file.
Specifically, modify the following variables:

- **ansible_master**

    Set the name and IP of the ansible master on section *Ansible*.

    Line template:
    ```yaml
    ansible_master: { name: <ansible_master_name>, ip: <ansible_master_ip }
    ```

    Line example:
    ```yaml
    ansible_master: { name: ansible1, ip: 172.16.40.39 }
    ```

- **add_new_nodes**

    Set this variable on section *Admin* to `true`.

    Line:
    ```yaml
    add_new_nodes: true
    ```
    
- **consul_public_ip**

    Set the Consul server public IP on section *Common*.

    Line template:
    ```yaml
    consul_public_ip: "<consul_public_ip>"
    ```

    Line example:
    ```yaml
    consul_public_ip: "193.146.75.205"


- **new_certs**

    Set this variable on section *Common* to the ZIP file name in which the certificates
    for the joining site will be created.

    > ⓘ It should just be the name of the ZIP file (without the .zip extension).
    > 
    > The ZIP file with that name will be created in `{{ path }}` and
    > should be handed over to the new site admins.

    Line template:
    ```yaml
    new_certs: "<new_certs_dir>"
    ```

    Example:
    ```yaml
    new_certs: "new_site_name"
    ```


## 3. Execute playbooks

Execute [playbook-admin-add.yaml](../playbook-admin-add.yaml) playbook to generate
the ZIP file.

```console
ansible-playbook -i <new_hosts_file> playbook-admin-add.yaml
```


## 4. Send ZIP file

Deliver the new ZIP file `<new_certs_dir>.zip` to the new site admins.
This file should be available on the Ansible master in the specified `{{ path }}`.

Default location: `/home/ubuntu/<new_certs_dir>.zip`.


## 5. Modify back group_vars

Modify [group_vars/all.yml](../group_vars/all.yml) to unset the previously set
variable in order to avoid future accidental executions.

- **add_new_nodes**

    Set this variable on section *Admin* to `false`.

    Line:
    ```yaml
    add_new_nodes: false
    ```
