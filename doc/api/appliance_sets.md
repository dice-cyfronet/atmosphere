## List user appliance sets

Get a list of user appliance sets. For normal user only owned appliance sets are returned, admin is able to set flag `all` into `true` (e.g. by adding `?all=true` to the request path) and thus receive all users appliance sets.

```
GET /appliance_sets
```

```json
{
  "appliance_sets": [
    {
        "id": 1,
        "name": "Foobar Appliance Set",
        "priority": 50,
        "appliance_set_type": "workflow"
    }, {
      ...
    }
  ]
}
```

## Details of an appliance set

Get all details of an appliance set.

```
GET /appliance_sets/:id
```

Parameters:

+ `id` (required) - The ID of an appliance set

```json
{
  "appliance_set": {
      "id": 1,
      "name": "Foobar Appliance Set",
      "priority": 50,
      "appliance_set_type": "workflow"
  }
}
```

## New appliance set

Creates a new appliance set. Every user is able to create one `portal` appliance set and many `workflow` appliance sets. Additionaly **developer** is able to create one `development` appliance set. Request format is the same as `GET` single Appliance Set response.

```
POST /appliance_sets
```

Parameters:

+ `name` (optional) - The name of the appliance set
+ `priority` (optional) - Appliance set priority
+ `appliance_set_type` (optional) - Appliance set type (`portal`, `workflow` or `development`). Default `workflow`

## Update appliance set

Update name and priority of user appliance set. You need to be an appliance type owner (or admin) do edit this appliance set.

```
PUT /appliance_sets/:id
```

Parameters:

+ `id` (required) - The ID of an appliance set
+ `name` (optional) - New appliance set name
+ `priority` (optional) - New appliance set priority

## Delete appliance set

Delete user appliance set. You need to be an appliance type owner (or admin) do delete this appliance set.

```
DELETE /appliance_sets/:id
```

Parameters:

+ `id` (required) - The ID of an appliance set

## List appliances added to appliance set

```
GET /appliance_sets/:id/appliances
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

## Add new appliance to appliance set

```
POST /appliance_sets/:id/appliances
```

Add new appliance to the appliance set

```json
{
  "appliance": {
      "configuration_template_id": 1,
      "params": {
        "param1": "param value",
        "param2": "another param",
        ...
      }
    }
}
```

Parameters:

+ `id` (required) - The ID of appliance set into which appliance will be added
+ `configuration_template_id` (required) - The ID of appliance configuration id used to instantiate appliance
+ `params` (optional) - if configuration template has dynamic content than params are used to inject concrete values into configuration placeholders.