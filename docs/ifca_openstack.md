# IFCA admin: Openstack configurations

<!-- todo: add new site IPs to security groups -->
This tutorial provides a guide to modify the IFCA OpenStack Security Groups to grant access to the new site that will join the federated cluster.


## 1. Add the new security rule

1. In section `Project > Network > Security Groups`.
2. Click on the `Manage Rule` of the group `Federation`.
3. Click `Add Rule`.

The new rule should be:

| Direction | Ether Type | IP Protocol | Port Range | Remote IP Prefix | Description |
| --- | --- | --- | --- | --- | --- |
| Ingress | IPv4 | TCP | Any | <new_site_subnet> | <New site's name> subnet 


## 2. Share rules with the new site admin

Send the whole list of rules in the `Federation`security group to the new site admin.
