## List user virtual machines

Get a list of virtual machines used by appliances added to user appliance sets. Normal user is able to list only virtual machines belonging to his/hers appliances. An admin is able to browse all users' virtual machines by adding the 'all' flag with value set to 'true' to query param.

```
GET /virtual_machines
```

```json
{
  "virtual_machines": [
    {
      "id": 1,
      "id_at_site": "7768b902-5e06-4730-9b43-6b8179e10233"
      "name": "Foobar Appliance Set",
      "state": "active",
      "ip": "10.100.1.24",
      "compute_site_id": 2,
      "virtual_machine_flavor_id": 1
    }, {
      ...
    }
  ]
}
```

To browse only virtual machines assigned to a specific appliance add `appliance_id` query param with appliance `id` (e.g. `/virtual_machines?appliance_id=1`).

## Details of a virtual machine

Get all details of a virtual machine.

```
GET /virtual_machines/:id
```

```json
{
  "virtual_machine": {
    "id": 1,
    "id_at_site": "7768b902-5e06-4730-9b43-6b8179e10233"
    "name": "Foobar Appliance Set",
    "state": "booting",
    "ip": "10.100.1.24",
    "compute_site_id": 2,
    "virtual_machine_flavor_id": 1
  }
}
```