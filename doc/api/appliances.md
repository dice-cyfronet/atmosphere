## List appliances

List all appliances belonging to the user. Appliances can belong to different user. Normal user is able to list only owned appliances, admin is able to set flag `all` into `true` (e.g. by adding `?all=true` to the request path) and thus receive information about all appliances.

```
GET /appliances
```

```json
{
  "appliances": [
    {
      "id": 1,
      "appliance_set_id": 2,
      "appliance_type_id": 3,
      "appliance_configuration_instance_id": 4
    }, {
      ...
    }
  ]
}
```

## Details of an appliance

Get all details of an appliance.

```
GET /appliances/:id
```

Parameters:

+ `id` (required) - The ID of an appliance

```json
{
  "appliance": {
    "id": 1,
    "appliance_set_id": 2,
    "appliance_type_id": 3,
    "appliance_configuration_instance_id": 4
  }
}
```

## <a name="post"></a> Add new appliance to appliance set

```
POST /appliances
```

Add new appliance to the appliance set

```json
{
  "appliance": {
      "configuration_template_id": 1,
      "appliance_set_id": 2,
      "params": {
        "param1": "param value",
        "param2": "another param",
        ...
      }
    }
}
```

Parameters:

+ `configuration_template_id` (required) - The ID of appliance configuration id used to instantiate appliance
+ `appliance_set_id` (required) - The ID of appliance set into which appliance will be added
+ `params` (optional) - if configuration template has dynamic content than params are used to inject concrete values into configuration placeholders.

## Delete appliance

Delete user appliance. You need to be an appliance owner (or admin) do delete it.

```
DELETE /appliances/:id
```

Parameters:

+ `id` (required) - The ID of an appliance