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
      "security_proxy_id": 1,
      "active": true
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
    "security_proxy_id": 1,
    active: false
  }
}
```

The `active` parameters set to true means that this `appliance type` is connected with one or more `virtual machine templates` and there is possible to spawn `appliance` from this appliance type. This parameter is read only.

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

+ `appliance_id` (required) - Appliance id started in development mode which will be used as a source for this appliance type.

All parameters presented bellow will overwrite parameters defined in `Dev Mode Property Set` correlated with source `Appliance`:

+ `name` (optional) - New appliance type name (required if `appliance_id` it empty)
+ `description` (optional) - New appliance type description
+ `shared` (optional) - `true`/`false` - defines if one virtual machine created from this appliance types can be shared amoung many users
+ `scalable` (optional) - `true`/`false` - defines if application delivered by this appliance type is able to be scalled up or down
+ `visible_for` (optional) - `owner` - default - appliance type can be used only by appliance type owner (in both development and production modes) / `developer` - appliance type can be started only in development mode / `all` - appliance type is production ready - it can be started in both development and production mode by everyone
+ `preference_cpu` (optional) - hint for optimalized to determine cpu required by the application installed on appliance type
+ `preference_memory` (optional) - hint for optimalized to determine memory (in MB) required by the application installed on appliance type
+ `preference_disk` (optional) - hint for optimalized to determine disk space (in MB) required by the application installed on appliance type
+ `author_id` (optional) - appliance type author id. If this value is not set than current user is set as an new `Appliance Type` owner.
+ `security_proxy_id` (optional) - security proxy configuration id used by this appliance type

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

## Get appliance type endpoint payload

Method used by Taverna to include appliance type endpoint descriptor (WSDL or WADL) into Taverna workbench.

```
GET /appliance_types/:id/endpoints/:service_name/:invocation_path
```

+ `id` (required) - The ID of an appliance type
+ `service_name` (required) - Port mapping template service name correlated with endpoint
+ `invocation_path` (required) - Endpoint invocation path