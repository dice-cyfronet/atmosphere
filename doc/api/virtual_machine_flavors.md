## List virtual machine flavors

Get a list of all virtual machine flavors at all compute sites.

```
GET /virtual_machine_flavors
```

```json
{
  "virtual_machine_flavors": [
    {
      "id": 1,
      "flavor_name": "Flavor 1",
      "active": true,
      "cpu": 1.0,
      "memory": 1024.0,
      "hdd": 512.0,
      "hourly_cost": 2100,
      "compute_site_id": 1,
      "id_at_site": "1",
      "supported_architectures":"x86_64"
    },
    {
      ...
    }
  ]
}
```

It is possible to filter virtual machine flavors based on either:
+ appliance_configuration_instance_id and optionally compute_site_id
+ appliance_type_id and optionally compute_site_id
+ a combination of compute_site_id, cpu, memory, hdd

If invalid filters are given, for example both appliance_configuration_instance_id and appliance_type_id are provided a 409 Conflict is returned.

Filters are expressed as query params.

### JSON fields meanings
+ `id` - flavor identifier
+ `flavor_name` - flavor name taken from compute site
+ `active` - true if compute site connected with this flavor is active, false otherwise
+ `cpu` - number of guaranteed VCPU
+ `memory` - number of guaranteed memory (in MB)
+ `hdd` - number of guaranteed hdd (in GB)
+ `hourly_cost` - cost calculated for every started hour when machine is runnig (1 = 0.0001 $)
+ `compute_site_id` - compute site identifier, where this flavor is available
+ `id_at_site` - internal compute site identifier
+ `supported_architectures` - what kind of VM can be started using this flavor (32 or 64 bit architecture)