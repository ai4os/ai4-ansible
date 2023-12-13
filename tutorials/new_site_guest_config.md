# New site: guest admin configuration



This tutorial assumes previous site creation following the prerequisite tutorial `tutorials/new_site_guest_initial.md`.

---

To join the federated cluster with a new site, its admin should follow the next steps from the **ansible master**.

1. Modify `hosts` file to match the new cluster configuration. Specifically, modify the following groups:
    - **consul_new_servers**
        
        Modify the line to match the new Consul server name and its public IP. 
        
        NOTE: there should only be one.
        
        Line template: `<new_server_name> ansible_host=<new_server_public_IP>`
        
        Example:
        
        ```
        [consul_new_servers]
        new-server ansible_host=193.146.75.194
        ```
        
    
    - **consul_new_clients**
        
        Modify the lines to match the new Consul client names and its IPs. 
        NOTE: use the public IPs when available (the Traefik node must always have public IP; but for the rest of the clients, it is optional). 
        
        Line template: `<new_client_name> ansible_host=<new_client_IP>`
        
        Example:
        
        ```
        [consul_new_clients]
        new-cpu-client ansible_host=172.16.43.137
        new-gpu-client1 ansible_host=172.16.43.58
        new-gpu-client2 ansible_host=172.16.43.59
        new-traefik ansible_host=193.146.75.162
        ```
        
    
    - **nomad_new_servers**
        
        Modify the line to match the new Nomad server name. Add its Nomad datacenter name. NOTE: there should only be one server.
        
        Line template: `<new_server_name> nomad_dc=<new_nomad_dc_name>`
        
        Example:
        
        ```
        [nomad_new_servers]
        new-server nomad_dc=my_new_nomad_dc
        ```
        
    
    - **nomad_new_gpu_clients**
        
        Modify the lines to match the new Nomad GPU client names. Add its Nomad datacenter name, domain and namespaces (if it belongs to both namespaces, separate them with just a comma)
        NOTE: if there are no GPU clients, leave the group empty (do not delete the group).
        
        Line template: `<new_gpu_client_name> nomad_dc=<new_nomad_dc_name> domain=<new_domain> nomad_namespaces=<namespace1,namespace2>`
        
        Example:
        
        ```
        [nomad_new_gpu_clients]
        new-gpu-client1 nomad_dc=my_new_nomad_dc domain=my_new_domain nomad_namespaces=ai4eosc,imagine
        new-gpu-client2 nomad_dc=my_new_nomad_dc domain=my_new_domain nomad_namespaces=imagine
        ```
        
    
    - **nomad_new_cpu_clients**
        
        Modify the lines to match the new Nomad CPU client names. Add its Nomad datacenter name, domain and namespaces (if both namespaces, separate them with just a comma).
        NOTE: CPU clients are those Nomad clients without GPU. The Traefik node should also be included in this group. If there are no CPU clients, leave the group empty (do not delete the group).
        
        Line template: `<new_cpu_client_name> nomad_dc=<new_nomad_dc_name> domain=<new_domain> nomad_namespaces=<namespace1,namespace2>`
        
        Example:
        
        ```
        [nomad_new_cpu_clients]
        new-cpu-client nomad_dc=my_new_nomad_dc domain=my_new_domain nomad_namespaces=ai4eosc,imagine
        new-traefik nomad_dc=my_new_nomad_dc domain=my_new_domain nomad_namespaces=ai4eosc,imagine
        ```
        
    
    - **nomad_new_volume**
        
        Modify the line to match the names of the new Nomad clients with an attached volume. Add its volume name and the name of its desired partition
        
        Line template: `<new_nomad_client_name> vol_name=<new_vol_name> partition_name=<new_partition_name>` 
        
        Example:
        
        ```
        [nomad_new_volume]
        new-cpu-client vol_name=vdb partition_name=part1
        new-gpu-client1 vol_name=vdb partition_name=part1
        ```
        
    
    - **traefik_new_master**
        
        Modify the line to match the new Traefik name. 
        
        NOTE: there should only be one.
        
        Line template: `<new_traefik_name>`
        
        Example:
        
        ```
        [traefik_new_master]
        new-traefik
        ```
        
    
2. Modify `group_vars/all.yml` file. Specifically, modify the following variable:
   
    - **ansible_master**
      
      Set the name and IP of the ansible master on section *Ansible*.
      
      Line template: `ansible_amster: { name: <ansible_master_name>, ip: <ansible_master_ip }`.
      
      Example:
      ```yaml
      ansible_master: { name: ansible1, ip: 172.16.40.39 }
      ```

    - **new_certs**
        
        Set this variable on section *Common* to the path on which the ZIP file with the cluster certificates will be extracted on the Ansible master. The directory name must be the same as the ZIP file name, and in the same path.
        NOTE: it is recommended to mantain `{{ path }}` and just append the name of the ZIP file to it, without the `.zip` extension.
        
        Line template: `new_certs:"{{ path }}<new_certs_dir>`"
        
        Example: 
        
        ```yaml
        new_certs: "{{ path }}new_site_name"
        ```

4. Place the ZIP file on the Ansible master in the specified `{{ path }}` (by default: `/home/ubuntu/<new_certs_dir>.zip`.
5. Execute `playbook-join-consul.yaml` playbook to join Consul.
    
    Execution command:
    
    ```bash
    ansible-playbook -i hosts playbook-join-consul.yaml
    ```

6. Execute `playbook-join-nomad.yaml` playbook to join Nomad.
    
    Execution command:
    
    ```bash
    ansible-playbook -i hosts playbook-join-nomad.yaml
    ```
    
7. Execute `playbook-join-traefik.yaml` playbook to configure the volumes, docker and the Traefik service.
    
    Execution command:
    
    ```bash
    ansible-playbook -i hosts playbook-join-traefik.yaml
    ```
