## List appliances

List all appliances belonging to the user. Appliances can belong to different user. Normal user is able to list only owned appliances, admin is able to set the `all` flag to `true` (e.g. by adding `?all=true` to the request path) and thus receive information about all appliances.

```
GET /appliances
```

```json
{
  "appliances": [
    {
      "id": 1,
      "name": "appliance name",
      "description": "appliance description",
      "appliance_set_id": 2,
      "appliance_type_id": 3,
      "appliance_configuration_instance_id": 4,
      "state": "satisfied", # or "unsatisfied"
      "state_explanation": "No matching flavor was found", # explanation why VM cannot be started for this appliance
      "amount_billed": 562123, # Amount billed for the use of this appliance since its creation, expressed in 1/10000 of base currency unit (which is defined in appliance.fund.currency and defaults to EUR. For example, 562123 stands for 56.21 Euro
      "prepaid_until": "2014-05-20 12:37", # The datetime stamp which determines how long this appliance will be allowed to run before being billed again. All times are UTC.
      "compute_site_ids": [1, 2], # IDs of compute sites on which this appliance is authorized to run VMs
      "virtual_machine_ids": [1, 2]
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
    "description": "appliance description",
    "appliance_set_id": 2,
    "appliance_type_id": 3,
    "appliance_configuration_instance_id": 4,
    "state": "satisfied", # or "unsatisfied"
    "state_explanation": "No matching flavor was found", # explanation why VM cannot be started for this appliance
    "amount_billed": 562123, # Amount billed for the use of this appliance since its creation, expressed in 1/10000 of base currency unit (which is defined in appliance.fund.currency and defaults to EUR. For example, 562123 stands for 56.21 Euro.
    "compute_site_ids": [1, 2], # IDs of compute sites on which this appliance is authorized to run VMs
    "virtual_machine_ids": [1, 2]
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
      "description": "appliance description",
      "user_key_id": 1, #only in development mode
      "configuration_template_id": 1,
      "compute_site_ids": [1, 2], # optional - if skipped, the appliance will be deployable to all existing compute sites.
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
+ `name` (optional) - Appliance name (if empty than source Appliance Type name is used)
+ `description` (optional) - Appliance description (if empty than source Appliance Type description is used)
+ `user_key_id` (optional) - User key id. User key will be rejected for appliances started in production mode
+ `configuration_template_id` (required) - The ID of appliance configuration id used to instantiate appliance
+ `params` (optional) - if configuration template has dynamic content than params are used to inject concrete values into configuration placeholders.
+ `dev_mode_property_set` (optional, allowed only in development mode) - list of preferences for new started machine. Allowed preferences: `preference_memory` (in MB), `preference_cpu`, `preference_disk` (in GB).

---

Not all appliance types can be added into all appliance sets. For details please take a look at [Appliance Type `visible_to` parameter description](appliance_types#visible_to). E.g. user is able to start Appliance Type with `visible_to` param set to `owner` only when he/she is  an owner of this Appliance Type, otherwise `403` (Forbidden) will be returned and no Appliance will be added to the Appliance Set.

---

## Update appliance name

Updates appliance name and description.

```
PUT /appliances/:id
```

Parameters:

+ `id` (required) - The ID of the Appliance to be updated

```json
{
  "appliance": {
      "name": "appliance name",
      "description": "appliance description",
    }
}
```

As a response full information about appliance is returned.

## Delete appliance

Delete user appliance. You need to be an appliance owner (or admin) to perform this action.

```
DELETE /appliances/:id
```

Parameters:

+ `id` (required) - The ID of an appliance

## Appliance actions

All actions which can be performed on appliance level have the same format.
Post messages need to be sent to:

```
POST /appliances/:id/action
```

with the following body:

```json
{
  "action_name": "action params"
}
```

Bellow you can find a list of all actions which can be performed on an appliance. If
the request JSON contains an invalid action name than `400` (Bad Request) status
code is returned.

### Restart appliance

For a regular user, their owned appliances started in `development` mode can be rebooted. Administrator
is able to reboot any appliance, started in any mode.

Request body:

```json
{
  "reboot": null
}
```

### Pause appliance

For a regular user, their owned appliances can be paused. Administrator
is able to pause any appliance.

Request body:

```json
{
  "pause": null
}
```

### Stop appliance

For a regular user, their owned appliances can be stopped. Administrator
is able to stop any appliance.

Request body:

```json
{
  "stop": null
}
```

### Suspend appliance

For a regular user, their owned appliances can be suspended. Administrator
is able to suspend any appliance.

Request body:

```json
{
  "suspend": null
}
```

### Start appliance

For a regular user, their owned appliances which are in paused mode can be started. Administrator is able to start any paused appliance.

Request body:

```json
{
  "start": null
}
```

## Get appliance endpoints

Get information about all endpoints registered for an appliance. HTTP mapping is performed asynchronously (once per 5s), thus information about endpoints will appear after HTTP redirections into running virtual machine(s) are established.

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
