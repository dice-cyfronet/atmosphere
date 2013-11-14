## List appliance types

Get a list of appliance types.

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
      "visible_for": "owner",
      "preference_cpu": 1.0,
      "preference_memory": 1024,
      "preference_disk": 10240,
      "author_id": 1,
      "security_proxy_id": 1
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
  "appliance_type": {
    "id": 1,
    "name": "Foobar Appliance Type",
    "description": "Foobar Appliance Type description",
    "shared": false,
    "scalable": true,
    "visible_for": "all",
    "preference_cpu": 1.0,
    "preference_memory": 1024,
    "preference_disk": 10240,
    "author_id": 1,
    "security_proxy_id": 1
  }
}
```

<a name="visible_for"></a> The `visible_for` parameter distinguish when such appliance type can be used. Allowed values are as follow:

+ `owner` - Appliance Type can be started in `development` and `production` mode but only by the Appliance Type `owner` (and `admin`). This kind of Appliance Types are only visible for the Appliance Type `owner` (and `admin`, when `all` flag is set to `true`)
+ `all` - Appliance Type can be started in `development` and `production` mode by `all` users
+ `developer` - Appliance Types with this type are only visible for the users with `developer` role (and `admin`) and they can be started only in `development` mode.

## Create new appliance type

Create new appliance type. Request format is the same as `GET` single Appliance Type response.

```
POST /appliance_types
```

Parameters:

+ `name` (required) - New appliance type
+ `description` (optional) - New appliance type description
+ `shared` (optional) - `true`/`false` - defines if one virtual machine created from this appliance types can be shared amoung many users.
+ `scalable` (optional) - `true`/`false` - defines if application delivered by this appliance type is able to be scalled up or down.
+ `visiblity` (required) - `unpublished` - appliance type can be used only in appliance sets started in development mode / `published` - appliance type is production ready.
+ `preference_cpu` (optional) - hint for optimalized to determine cpu required by the application installed on appliance type.
+ `preference_memory` (optional) - hint for optimalized to determine memory (in MB) required by the application installed on appliance type.
+ `preference_disk` (optional) - hint for optimalized to determine disk space (in MB) required by the application installed on appliance type.
+ `author_id` (optional) - appliance type author id.
+ `security_proxy_id` (optional) - security proxy configuration id used by this appliance type.

## Update appliance type

Update appliance set properties. You need to be an appliance type owner (or admin) do edit this entity. Request format is the same as `GET` single Appliance Type response.

```
PUT /appliance_types/:id
```

Parameters:

+ `id` (required) - The ID of an appliance type
+ All other parameters are optional and are the same as for `POST` method

## Delete appliance type

Delete user appliance type. You need to be an appliance type owner (or admin) do delete this entity.

```
DELETE /appliance_types/:id
```

Parameters:

+ `id` (required) - The ID of an appliance type