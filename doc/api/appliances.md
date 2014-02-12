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
      "name": "appliance name",
      "appliance_set_id": 2,
      "appliance_type_id": 3,
      "appliance_configuration_instance_id": 4,
      "state": "satisfied", (or "unsatisfied")
      "state_explanation": "No matching flavor was found" (explanation why VM cannot be started for this appliance)
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
    "name": "appliance name",
    "appliance_set_id": 2,
    "appliance_type_id": 3,
    "appliance_configuration_instance_id": 4,
    "state": "satisfied", (or "unsatisfied")
    "state_explanation": "No matching flavor was found" (explanation why VM cannot be started for this appliance)
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
      "appliance_set_id": 2,
      "name": "appliance name",
      "user_key_id": 1, #only in development mode
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

+ `appliance_set_id` (required) - The ID of appliance set into which appliance will be added
+ `name` (optional) - Appliance name
+ `user_key_id` (optional) - User key id. User key will be rejested for appliances started in production mode
+ `configuration_template_id` (required) - The ID of appliance configuration id used to instantiate appliance
+ `params` (optional) - if configuration template has dynamic content than params are used to inject concrete values into configuration placeholders.
+ `dev_mode_property_set` (optional, allowed only in development mode) - list of preferences for new started machine. Allowed preferences: `preference_memory` (in MB), `preference_cpu`, `preference_disk` (in GB).

---

Not all appliance types can be added into all appliance sets. For details please take a look at [Appliance Type `visible_to` parameter description](appliance_types#visible_to). E.g. user is able to start Appliance Type with `visible_to` param set to `owner` only when he/she is  an owner of this Appliance Type, otherwise `403` (Forbidden) will be returned and no Appliance will be added into Appliance Set.

---

## Update appliance name

Updates appliance name.

```
PUT /appliances/:id
```

Parameters:

+ `id` (required) - The ID of the Appliance to be updated

```json
{
  "appliance": {
      "name": "appliance name"
    }
}
```

As a response full information about appliance is returned.

## Delete appliance

Delete user appliance. You need to be an appliance owner (or admin) do delete it.

```
DELETE /appliances/:id
```

Parameters:

+ `id` (required) - The ID of an appliance

## Get appliance endpoints

Get information about all endpoints registered into appliance. Http mappings generation is done in asynchronous way (once per 5s), thus information about endpoints will appear after http redirections into started virtual machine(s) are established.

```
GET /appliances/:id/endpoints
```

Parameters:

+ `id` (required) - The ID of an appliance

```json
{
  endpoints: [
    {
      id: 1,
      type: "ws", "rest" or "webapp",
      urls: [
        "http://http.redirection",
        "https://https.redirection",
        ...
      ]
    }, {
      ...
    }
  ]
}
```