## List user appliance sets

Get a list of user appliance sets

```
GET /appliance_sets
```

```json
[
    {
        "id": 1,
        "name": "Foobar Appliance Set",
        "priority": 50,
        "type": "workflow"
    }
]
```

## Details of an appliance set

Get all details of an appliance set.

```
GET /appliance_sets/:id
```

Parameters:

+ `id` (required) - The ID of an appliance set

## New appliance set

Creates a new appliance set. Every user is able to create one portal appliance set and many workflow appliance sets. Additionaly developer is able to create one development appliance set.

```
POST /appliance_sets
```

Parameters:

+ `name` (optional) - The name of the appliance set
+ `priority` (optional) - Appliance set priority
+ `type` (optional) - Appliance set type (`portal`, `workflow` or `development`). Default `workflow`

## Update appliance set

Update name and priority of user appliance set.

```
PUT /appliance_sets/:id
```

Parameters:

+ `id` (required) - The ID of an appliance set
+ `name` (optional) - New appliance set name
+ `priority` (optional) - New appliance set priority

## Delete appliance set

Delete user appliance set

```
DELETE /appliance_sets/:id
```

Parameters:

+ `id` (required) - The ID of an appliance set