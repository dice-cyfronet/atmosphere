## List appliance configuration instances

Get a list of appliance configuration instances. A regular user is only allowed to see the the configuration instances connected with owned appliances.

```
GET /appliance_configuration_instances
```

```json
{
  "appliance_configuration_instances": [
    {
      "id": 587,
      "payload": "configuration instance instance (it is injected into VM)",
      "appliance_configuration_template_id": 222,
      "appliance_ids": [698, 765]
    }, {
      ...
    }
  ]
}
```

To browse only appliance configuration instances assigned into an appliance add `appliance_id` query param with appliance `id` (e.g. `/appliance_configuration_instances?appliance_id=1`).

## Details of an appliance configuration instance

Get all details of an appliance configuration instance.

```
GET /appliance_configuration_instances/:id
```
Parameters:

+ `id` (required) - The ID of an appliance configuration instance

```json
{
  "appliance_configuration_instance": {
    "id": 587,
    "payload": "configuration instance instance (it is injected into VM)",
    "appliance_configuration_template_id": 222,
    "appliance_ids": [698, 765]
  }
}
```