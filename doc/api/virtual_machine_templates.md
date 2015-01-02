## List user virtual machines

Get a list of virtual machines used by appliances added to user appliance sets. Normal user is able to list only virtual machine templates managed by atmosphere and belonging to appliance types visible to the user. Admin is able to browse all virtual machine templates by adding the 'all' flag with value set to 'true' into query param.

```
GET /virtual_machine_templates
```

```json
{
  "virtual_machine_templates": [
    {
      "id": 1,
      "id_at_site": "7768b902-5e06-4730-9b43-6b8179e10233"
      "name": "Foobar Virtual Machine Template",
      "state": "active",
      "compute_site_id": 2,
      "managed_by_atmosphere": true,
      "architecture": "x86_64",
      "appliance_type_id": 1
    }, {
      ...
    }
  ]
}
```