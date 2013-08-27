## List appliance types

Get a list of appliance types

```
GET /appliance_types
```

```json
{
  "appliance_types": [
    {
      "id": 1,
      "name": "Foobar Appliance Type",
      "description": "Foobar Appliance Type description",
      "shared": false,
      "scalable": true,
      "visibility": "published",
      "preference_cpu": 1.0,
      "preference_memory": 1024,
      "preference_disk": 10240,
      "author": "marek",
      "security_proxy": "/security/proxy/name"
    }, {
      ...
    }
  ]
}
```

## Details of an appliance type

Get all details of an appliance type.

```
GET /appliance_types/:id
```

Parameters:

+ `id` (required) - The ID of an appliance type

```json
{
  "appliance_types": [
    {
      "id": 1,
      "name": "Foobar Appliance Type",
      "description": "Foobar Appliance Type description",
      "shared": false,
      "scalable": true,
      "visibility": "published",
      "preference_cpu": 1.0,
      "preference_memory": 1024,
      "preference_disk": 10240,
      "author": "marek",
      "security_proxy": "/security/proxy/name"
    }
  ]
}
```

## Update appliance type

Update appliance set properties. You need to be an appliance type owner (or admin) do edit this entity.

```
PUT /appliance_types/:id
```

Parameters:

+ `id` (required) - The ID of an appliance type
+ `name` (optional) - New appliance type
+ `description` (optional) - New appliance type description
+ `shared` (optional) - `true`/`false` - defines if one virtual machine created from this appliance types can be shared amoung many users.
+ `scalable` (optional) - `true`/`false` - defines if application delivered by this appliance type is able to be scalled up or down.
+ `visiblity` (optional) - `unpublished` - appliance type can be used only in appliance sets started in development mode / `published` - appliance type is production ready.
+ `preference_cpu` (optional) - hint for optimalized to determine cpu required by the application installed on appliance type.
+ `preference_memory` (optional) - hint for optimalized to determine memory (in MB) required by the application installed on appliance type.
+ `preference_disk` (optional) - hint for optimalized to determine disk space (in MB) required by the application installed on appliance type.

## Delete appliance type

Delete user appliance type. You need to be an appliance type owner (or admin) do delete this entity.

```
DELETE /appliance_types/:id
```

Parameters:

+ `id` (required) - The ID of an appliance type