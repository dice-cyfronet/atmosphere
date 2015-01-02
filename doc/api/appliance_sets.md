## List user appliance sets

Get a list of user appliance sets. For normal users only owned appliance sets are returned. An admin is able to set the `all` flag to `true` (e.g. by adding `?all=true` to the request path) and thus receive all users' appliance sets.

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

Create a new appliance set. Every user is able to create one `portal` appliance set and many `workflow` appliance sets. Additionally **developer** is able to create one `development` appliance set.

```
POST /appliance_sets
```

Parameters:

```json
{
  "appliance_set": {
    "name": "Foobar Appliance Set",
    "priority": 50,
    "appliance_set_type": "workflow",
    "optimalization_policy": "manual",
    "appliances": [
      { 
        "configuration_template_id": 1, 
        "params": { "a": "piersza wartosc, "b": "druga wartosc" },
        "vms": [
           { "cpu": 1, "mem": 512, compute_site_ids: [1] }
        ]
      }
    ]
  }
}
```

Parameters:

+ `name` (optional) - The name of the appliance set
+ `priority` (optional) - Appliance set priority (number between 1 and 100)
+ `appliance_set_type` (optional) - Appliance set type (`portal`, `workflow` or `development`). Default `workflow`.
+ `optimization_policy` (optional) - Optimization policy that will be used to allocate resources for the appliance set. Allowed values: `manual` and `default`. Default value is `default`.
+ `appliances` (optional) - An array of hashes each defining an appliance that will be added to the appliance set. Hash for a single appliance contains the following parameters:
    + `configuration_template_id` (required if `appliances` parameter is provided) - The ID of appliance configuration id used to instantiate appliance.
    + `params` (optional) - if configuration template has dynamic content than params are used to inject specific values into configuration placeholders.
    + `vms` (optional) - if `manual` optimization policy is selected (see `optimization_policy` parameter) then this parameter provides a specification of virtual machines that will be spawned for an appliance. The format of this parameter is the an array of hashes. Hash for single virtual machine may contain the following keys:
        + `cpu` (optional) - How many cpu cores are required for a virtual machine.
        + `mem` (optional) - How much RAM memory is required for a virtual machine.
        + `compute_site_ids` (optional) - An array of ids of compute sites that can be used to host virtual machine. 



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

Delete user appliance set. You need to be an appliance set owner (or admin) do delete it.

```
DELETE /appliance_sets/:id
```

Parameters:

+ `id` (required) - The ID of an appliance set