
# Consul and Nomad version update: Ansible deployment

> ⓘ  **Requirements** \
> This tutorial assumes the nodes are already configured and running.


## 1. Configure hosts

Copy [hosts_update_template](../hosts_update_template) into a new hosts file
(e.g. `myhosts`).

Modify the new hosts file to match the cluster configuration. An example can be
found on [hosts_update_example](../hosts_update_example).
Specifically, modify the following groups:

- **version_update**

    Modify the line to match each node name and its IP.

    > ⚠ These will be the nodes on which the version update will be carried out.

    Line template:
    ```ini
    <node1_name> ansible_host=<node1_public_IP>
      ...
    <nodeN_name> ansible_host=<nodeN_public_IP>
    ```

    Group example:
    ```ini
    [version_update]
    node-ifca-0 ansible_host=193.146.75.205
    node-ifca-1 ansible_host=172.16.44.95
    node-ifca-gpu-0 ansible_host=172.16.44.233
    node-ifca-traefik ansible_host=193.146.75.208
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

- **nomad_version**
  
    Set the number of Nomad version on section *Nomad*.


    Line template:
    ```yaml
    nomad_version: <number_of_nomad_version>
    ```

    Line example:
    ```yaml
    nomad_version: 1.7.2
    ```

- **consul_version**
  
    Set the number of Consul version on section *Consul*.


    Line template:
    ```yaml
    consul_version: <number_of_consul_version>
    ```

    Line example:
    ```yaml
    consul_version: 1.17.1
    ```



## 4. Execute playbook

* Execute [playbook-update-version.yaml](../playbook-update-version.yaml) playbook to update the versions.

    ```console
    ansible-playbook -i <new_hosts_file> playbook-update-version.yaml
    ```
