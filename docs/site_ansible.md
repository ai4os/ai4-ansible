# New site: Ansible configuration

> ⓘ  **Requirements** \
> This tutorial assumes you already have completed the
> [Openstack configuration](./site_openstack.md) of your site.

To join the federated cluster with a new site, its admin should follow the following
steps from the [Ansible master](../README.md#ansible-configuration).


## 1. Modify hosts

Modify [hosts](../hosts) file to match the new cluster configuration.
Specifically, modify the following groups:

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
    new-cpu-client ansible_host=172.16.43.137
    new-gpu-client1 ansible_host=172.16.43.58
    new-gpu-client2 ansible_host=172.16.43.59
    new-traefik ansible_host=193.146.75.162
    ```

- **nomad_new_servers**

    Modify the line to match the new Nomad server name. Add its Nomad datacenter name.

    > ⚠ There should only be one Nomad server.

    Line template:
    ```ini
    <new_server_name> nomad_dc=<new_nomad_dc_name>
    ```

    Group example:
    ```ini
    [nomad_new_servers]
    new-server nomad_dc=my_new_nomad_dc
    ```

- **nomad_new_gpu_clients**

    Modify the lines to match the new Nomad GPU client names. Add its Nomad datacenter name, domain and namespaces (if it belongs to both namespaces, separate them with just a comma).

    > ⚠ If there are no GPU clients, leave the group empty (**do not delete the group**).

    Line template:
    ```ini
    <new_gpu_client_name> nomad_dc=<new_nomad_dc_name> domain=<new_domain> nomad_namespaces=<namespace1,namespace2>
    ```

    Group example:
    ```ini
    [nomad_new_gpu_clients]
    new-gpu-client1 nomad_dc=my_new_nomad_dc domain=my_new_domain nomad_namespaces=ai4eosc,imagine
    new-gpu-client2 nomad_dc=my_new_nomad_dc domain=my_new_domain nomad_namespaces=imagine
    ```

- **nomad_new_cpu_clients**

    Modify the lines to match the new Nomad CPU client names. Add its Nomad datacenter name, domain and namespaces (if both namespaces, separate them with just a comma).

    > ⓘ CPU clients are Nomad clients without GPU. The Traefik node should also be
    > included in this group.

    > ⚠ If there are no CPU clients, leave the group empty (**do not delete the group**).
    <!-- todo: cambiar -->

    Line template:
    ```ini
    <new_cpu_client_name> nomad_dc=<new_nomad_dc_name> domain=<new_domain> nomad_namespaces=<namespace1,namespace2>`
    ```

    Group example:
    ```ini
    [nomad_new_cpu_clients]
    new-cpu-client nomad_dc=my_new_nomad_dc domain=my_new_domain nomad_namespaces=ai4eosc,imagine
    new-traefik nomad_dc=my_new_nomad_dc domain=my_new_domain nomad_namespaces=ai4eosc,imagine
    ```

- **nomad_new_volume**

    <!-- todo: move to the end? -->

    Modify the line to match the names of the new Nomad clients with an attached volume. Add its volume name and the name of its desired partition.

    Line template:
    ```ini
    <new_nomad_client_name> vol_name=<new_vol_name> partition_name=<new_partition_name>
    ````

    Group example:
    ```ini
    [nomad_new_volume]
    new-cpu-client vol_name=vdb partition_name=part1
    new-gpu-client1 vol_name=vdb partition_name=part1
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

## 2. Modify group_vars

Modify [group_vars/all.ym](../group_vars/all.yml) file.
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

- **new_certs**

    Set this variable on section *Common* to the path on which the ZIP file with the
    cluster certificates will be extracted on the Ansible master.

    > ⓘ It is recommended to keep `{{ path }}` and just append the name of the ZIP
    > filename to it (without the `.zip` extension).

    Line template:
    ```yaml
    new_certs: "{{ path }}<new_certs_dir>"
    ```

    Line example:
    ```yaml
    new_certs: "{{ path }}new_site_name"
    ```

<!-- todo: add your Traefik certs to group vars -->





<!-- todo: additional step: send host file to ifca admin -->

## 3. Place ZIP file

Place the ZIP file, that you should have received from the IFCA admin,
on the Ansible master at the specified `{{ path }}`.

Default location: `/home/ubuntu/<new_certs_dir>.zip`.


## 4. Execute playbooks

* Execute [playbook-join-consul.yaml](../playbook-join-consul.yaml) playbook to join Consul.

    ```console
    ansible-playbook -i hosts playbook-join-consul.yaml
    ```

* Execute [playbook-join-nomad.yaml](../playbook-join-nomad.yaml) playbook to join Nomad.

    ```console
    ansible-playbook -i hosts playbook-join-nomad.yaml
    ```

* Execute [playbook-join-traefik.yaml](../playbook-join-traefik.yaml) playbook to configure the volumes, docker and the Traefik service.

    ```console
    ansible-playbook -i hosts playbook-join-traefik.yaml
    ```
