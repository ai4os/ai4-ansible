# Create a federated cluster: Ansible deployment

> ⓘ  **Requirements** \
> This tutorial assumes you already have completed the
> [Openstack configuration](./site_openstack.md) of the cluster.

To create the federated cluster, the IFCA admin should follow the 
steps from the [Ansible master](../README.md#ansible-configuration).


## 1. Configure hosts

Copy [hosts_ifca_admin_deploy_template](../hosts_ifca_admin_deploy_template) into a new hosts file
(e.g. `myhosts`).

Modify the new hosts file to match the cluster configuration. An example can be
found on [hosts_ifca_admin_deploy_example](../hosts_ifca_admin_deploy_example).
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


- **consul_clients**

    Modify the lines to match the names of the Consul clients and their IPs.

    > ⚠ The Traefik node must always have public IP.
    > For the rest of the clients, public IPs are optional.

    Line template:
    ```ini
    <client1_name> ansible_host=<client1_IP>
      ...
    <clientN_name> ansible_host=<clientN_IP>
    ```

    Group example:
    ```ini
    [consul_clients]
    node-ifca-traefik ansible_host=193.146.75.208
    node-ifca-1 ansible_host=172.16.44.26
    node-ifca-gpu-0 ansible_host=172.16.44.233
    ```

- **traefik_master**

    Modify the line to match the Traefik name.

    > ⚠ There should only be one Traefik instance.

    Line template:
    ```ini
    <traefik_name>
    ```

    Group example:
    ```ini
    [traefik_master]
    node-ifca-traefik
    ```

- **nomad_master**

    Modify the line to match the IFCA Nomad master name. Add its Nomad datacenter name.

    > ⚠ There should only be one Nomad master, which matches with the Consul master.

    Line template:
    ```ini
    <server_name> nomad_dc=<nomad_dc_name>
    ```

    Group example:
    ```ini
    [nomad_master]
    node-ifca-0 nomad_dc=ifca-ai4eosc
    ```


- **nomad_cpu_clients**

    Modify the lines to match the Nomad CPU client names.
    Add its Nomad datacenter name, domain and namespaces.

    > ⚠ CPU clients are Nomad clients without GPU. The Traefik node should also be
    > included in this group.
    > Therefore there should **always be at least 1 CPU client**: the Traefik node.

  
    + A Nomad client can belong to one _namespace_ or more (if more, separate them with just a
      comma).
    + The _domain_ is the hostname where the deployments will be accessible.
      All clients should share the same domain.
      Eg. if `domain=ifca` and the cluster belongs to the `imagine` _namespace_,
      the deployments will be accessible under:
      `*.<domain>-deployments.cloud.imagine-ai.eu`


    Line template:
    ```ini
    <cpu_client1_name> nomad_dc=<nomad_dc_name> domain=<domain> nomad_namespaces=<namespace1,namespace2>
      ...
    <cpu_clientN_name> nomad_dc=<nomad_dc_name> domain=<domain> nomad_namespaces=<namespace1,namespace2>
    ```

    Group example:
    ```ini
    [nomad_cpu_clients]
    node-ifca-traefik nomad_dc=ifca-ai4eosc domain=ifca nomad_namespaces=ai4eosc,imagine,tutorials
    node-ifca-1 nomad_dc=ifca-ai4eosc domain=ifca nomad_namespaces=ai4eosc,imagine,tutorials
    ```

- **nomad_gpu_clients**

    Modify the lines to match the Nomad GPU client names.
    Add its Nomad datacenter name, domain and namespaces.

    > ⚠ If there are no GPU clients, leave the group empty (**do not delete the group**).

    Line template:
    ```ini
    <gpu_client1_name> nomad_dc=<nomad_dc_name> domain=<domain> nomad_namespaces=<namespace1,namespace2>
      ...
    <gpu_clientN_name> nomad_dc=<nomad_dc_name> domain=<domain> nomad_namespaces=<namespace1,namespace2>
    ```

    Group example:
    ```ini
    [nomad_gpu_clients]
    node-ifca-gpu-0 nomad_dc=ifca-ai4eosc domain=ifca nomad_namespaces=ai4eosc,imagine,tutorials
    ```

- **nomad_volume**

    Modify the line to match the names of the Nomad clients with an attached volume.
    Add its volume name and the name of its desired partition.

    Line template:
    ```ini
    <_nomad_client1_name> vol_name=<vol_name> partition_name=<partition_name>
      ...
    <nomad_clientN_name> vol_name=<vol_name> partition_name=<partition_name>
    ```

    Group example:
    ```ini
    [nomad_volume]
    node-ifca-1 vol_name=vdb partition_name=part1
    node-ifca-gpu-0 vol_name=vdb partition_name=part1
    ```


- **monitoring**

    Modify the line to match the names of the Nomad server.

    Line template:
    ```ini
    <server_name>
    ```

    Group example:
    ```ini
    [monitoring]
    node-ifca-0
    ```


## 2. Create Traefik certificates

SSL certificates are needed for the Traefik node.
For this:

- Remember the `domain` name selected in the previous step, when configuring
  cpu/gpu clients.
- Send an email to the provided contact person asking for certificates covering:
  + `<domain>-deployments.cloud.ai4eosc.eu` (for AI4EOSC sites)
  + `*.<domain>-deployments.cloud.ai4eosc.eu` (for AI4EOSC sites)
  + `<domain>-deployments.cloud.imagine-ai.eu` (for iMagine sites)
  + `*.<domain>-deployments.cloud.imagine-ai.eu` (for iMagine sites)
- You will receive a reply with a `.key` file.
- You will receive an email with several `.pem` files.
  Download the one stating **Certificate (w/ issuer after), PEM encoded**.
- Put both files (`.key`and `.pem`) in a folder and zip the content (`<traefik_certs>.zip`).
- Go to [nsupdate](https://nsupdate.fedcloud.eu/) and log with your EGI credentials.
  You should be able to see you new domains in `Overview`.
  Go to each host and use `Set new IPv4 address` to set the IP address to the public IP
  of your Traefik node.

Once having obtained the ZIP file, place it in the Ansible master. By default it should go
under `/home/ubuntu/`:

- `/home/ubuntu/<traefik_certs>.zip`.


## 3. Modify group_vars

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

- **path**

    This should be the folder where the Traefik ZIP file certs from
    the previous step was placed.

    Line template:
    ```yaml
    path: <cert_folder_path>
    ```

    Line example:
    ```yaml
    path: /home/ubuntu/
    ```

- **consul_public_ip**

    Set the Consul public IP of the federated cluster on section *Common*.
    This should be the IP of the Consul master.

    Line template:
    ```yaml
    consul_public_ip: "<consul_public_ip>"
    ```

    Line example:
    ```yaml
    consul_public_ip: "193.146.75.205"


- **traefik_certs**

    Set this variable on section *Traefik* to the name of the the ZIP file with the
    Traefik certificates which will be extracted on the Ansible master.

    > ⓘ It should just be the name of the ZIP file (**without** the `.zip` extension).

    Line template:
    ```yaml
    traefik_certs: <new_traefik_certs_zip_name>
    ```

    Line example:
    ```yaml
    traefik_certs: ifca-deployments.cloud.ai4eosc.eu
    ```

- **nomad_namespaces**

    Set this variable on section *Nomad* to the list of Nomad namespaces to create.

    > ⓘ It should be a list with each namespace in a new line, starting with a dash `-`.

    Line template:
    ```yaml
    nomad_namespaces:
      - <namespace1>
          ...
      - <namespaceN>
    ```

    Line example:
    ```yaml
    nomad_namespaces:
      - ai4eosc
      - imagine
      - tutorials
    ```


## 4. Execute playbooks

* Execute [playbook-consul.yaml](../playbook-consul.yaml) playbook to deploy
  Consul.

    ```console
    ansible-playbook -i <new_hosts_file> playbook-consul.yaml
    ```

* Execute [playbook-nomad.yaml](../playbook-nomad.yaml) playbook to deploy
  Nomad.

    ```console
    ansible-playbook -i <new_hosts_file> playbook-nomad.yaml
    ```

* Execute [playbook-traefik.yaml](../playbook-traefik.yaml) playbook to
  configure the volumes, docker and the Traefik service.

    ```console
    ansible-playbook -i <new_hosts_file> playbook-traefik.yaml
    ```
