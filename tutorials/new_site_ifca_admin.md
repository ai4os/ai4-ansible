# New site: IFCA admin steps

To add a new site to the federated cluster, an **IFCA admin** should follow the next steps from the **ansible master**.

1. Modify `hosts` file to match the new cluster configuration. Specifically, modify the following groups:
    - **consul_new_servers**
        
        Modify the line to match the new Consul server name and its public IP. NOTE: there should only be one.
        
        Line template: `<new_server_name> ansible_host=<new_server_public_IP>`
        
        Example:
        
        ```
        [consul_new_servers]
        new-server ansible_host=193.146.75.194
        ```
        
    
    - **consul_new_clients**
        
        Modify the lines to match the new Consul client names and its IPs. NOTE: use the public IPs when available (the Traefik node must always have public IP; but for the rest of the clients, it is optional). 
        
        Line template: `<new_client_name> ansible_host=<new_client_IP>`
        
        Example:
        
        ```
        [consul_new_clients]
        new-cpu-client ansible_host=172.16.43.137
        new-gpu-client ansible_host=172.16.43.58
        new-traefik ansible_host=193.146.75.162
        ```
        
    
    - **nomad_new_servers**
        
        Modify the line to match the new Nomad server name. NOTE: there should only be one.
        
        Line template: `<new_server_name>`
        
        Example:
        
        ```
        [nomad_new_servers]
        new-server
        ```
        
    
    - **nomad_new_gpu_clients**
        
        Modify the lines to match the new Nomad GPU client names. NOTE: if there are no GPU clients, leave the group empty (do not delete the group).
        
        Line template: `<new_gpu_client_name>`
        
        Example:
        
        ```
        [nomad_new_gpu_clients]
        new-gpu-client
        ```
        
    
    - **nomad_new_cpu_clients**
        
        Modify the lines to match the new Nomad CPU client names. NOTE: CPU clients are those Nomad clients without GPU. The Traefik node should not be included in this group. If there are no CPU clients, leave the group empty (do not delete the group).
        
        Line template: `<new_cpu_client_name>`
        
        Example:
        
        ```
        [nomad_new_cpu_clients]
        new-cpu-client
        ```
        
    
    - **traefik_new_master**
        
        Modify the line to match the new Traefik name. NOTE: there should only be one.
        
        Line template: `<new_traefik_name>`
        
        Example:
        
        ```
        [traefik_new_master]
        new-traefik
        ```
        
    
2. Modify `group_vars/all.yml` file. Specifically, modify the following variables:
    - **add_new_nodes**
        
        Set this variable on section *Admin* to true. 
        
        Line: 
        
        ```yaml
        add_new_nodes: true
        ```
        
    - **new_certs**
        
        Set this variable on section *Common* to the path in which the certificates for the joining site will be created. NOTE: it is recommended to mantain `{{ path }}` and just append the name of the new directory to it. This will be the name of the ZIP file that should be handed over to the new site admins.
        
        Line template: `new_certs:"{{ path }}<new_certs_dir>`"
        
        Example: 
        
        ```yaml
        new_certs: "{{ path }}new_site_name"
        ```
        

3. Execute `playbook-admin-add.yaml` playbook to generate the ZIP file.
    
    Execution command:
    
    ```bash
    ansible-playbook -i hosts playbook-admin-add.yaml
    ```


    
4. Deliver the new ZIP file `<new_certs_dir>.zip` to the new site admins. This file should be available on the Ansible master in the specified `{{ path }}` (by default: `/home/ubuntu/<new_certs_dir>.zip`.

5. Modify `group_vars/all.yml` to unset the previously set variable in order to avoid future accidental executions.
    - **add_new_nodes**
        
        Set this variable on section *Admin* to false. 
        
        Line: 
        
        ```yaml
        add_new_nodes: false
        ```
