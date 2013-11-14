## List development appliances property sets

Get list of properties assigned into appliance started in development mode. This type of resources is available only for *developers* and *admins*. Developer is able to see development appliance properties connected only with owned appliance (which is started in development mode). Administrator is able to see all appliance development properties by setting query parameter `all` into `true`

Appliance development property set is used while appliance is being saved as appliance type.

```
GET /dev_mode_property_sets
```

```json
{
  "dev_mode_property_sets": [
    {
      "id": 16,
      "name": "new appliance type",
      "description": "new funcy appliance type",
      "shared": false,
      "scalable": false,
      "preference_cpu": 1,
      "preference_memory": 1024,
      "preference_disk": 10240,
      "appliance_id": 16,
      "security_proxy_id": 23,
      "port_mapping_template_ids": [6, 8]
    }, {
      ...
    }
  ]
}
```

## Details of an appliance development property set

Get all details of a development appliance property set.

```
GET /dev_mode_property_sets/:id
```

Parameters:

+ `id` (required) - The ID of an development appliance property set

```json
{
  "dev_mode_property_sets": {
    "id": 16,
    "name": "new appliance type",
    "description": "new funcy appliance type",
    "shared": false,
    "scalable": false,
    "preference_cpu": 1,
    "preference_memory": 1024,
    "preference_disk": 10240,
    "appliance_id": 16,
    "security_proxy_id": 23,
    "port_mapping_template_ids": [6, 8]
  }
}
```

## Update development appliance  property set.

Update development appliance property set. You need to be an appliance type owner (or admin) do edit this entity. Request format is the same as `GET` single development appliance property set response.

```
PUT /dev_mode_property_sets/:id
```

Parameters:

+ `id` (required) - The ID of an appliance type
+ All other parameters are optional and are the same as in `GET /dev_mode_property_sets/:id` methods except `id`, `appliance_id` and `port_mapping_template_ids`, which are read only values.