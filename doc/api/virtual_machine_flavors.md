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

It is possible to filter virtual machine flavors based on:

+ appliance type id - selects flavors that are avaiable for templates of given ApplianceType.
+ required cpu - selects flavors that have at least given number of cpus.
+ required memory - selects flavors that have at least given memory size.
+ required HDD - selects flavors that have at least given HDD size.
+ compute site id - selects flavors available at given compu site.

Filters are expressed as query params. Filters can be combined together.