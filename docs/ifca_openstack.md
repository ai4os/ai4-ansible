# IFCA admin: Openstack configurations

<!-- todo: add new site IPs to security groups -->
This tutorial provides a guide to grant access to the new site that will join the federated cluster.


## 1. Add the new security rule

Modify the OpenStack ecurity group `Federation`to add the new rule.

1. In section `Project > Network > Security Groups`.
2. Click on the `Manage Rule` of the group `Federation`.
3. Click `Add Rule`.

The new rule should be:

| Direction | Ether Type | IP Protocol | Port Range | Remote IP Prefix | Description |
| --- | --- | --- | --- | --- | --- |
| Ingress | IPv4 | TCP | Any | <new_site_subnet> | <New site's name> subnet 


## 2. Share rules

Send the whole list of rules in the `Federation` security group to each adminto of each site within the federation.

## 3. Proceed with the Ansible part

Follow the [ifca_openstack.md](ifca_openstack.md) instructions.
