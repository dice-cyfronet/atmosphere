## List Port Mapping Properties

Get a list of Port Mapping Properties defined for a given Port Mapping Template.

```
GET /port_mapping_properties
```

Parameters:

+ `port_mapping_template_id` (required) - The ID of the specific Port Mapping Template which Port Mapping Properties you'd like to get

```json
{
  "port_mapping_properties": [
    {
      "id": 1,
      "key": "property_key_string",
      "value": "property_value_string",
      "compute_site_id": nil (should always be nil),
      "port_mapping_template_id": 5 (should equal the :port_mapping_template_id parameter)
    }, {
      ...
    }
  ]
}
```


## Details of a Port Mapping Property

Get the full JSON document about a given Port Mapping Property.

```
GET /port_mapping_properties/:id
```

Parameters:

+ `id` (required) - The ID of the Port Mapping Property you are interested in

```json
{
  "port_mapping_property": {
    "id": 1 (should equal the :id parameter),
    "key": "property_key_string",
    "value": "property_value_string",
    "compute_site_id": nil (should always be nil),
    "port_mapping_template_id": 5
  }
}
```


## Create a Port Mapping Property

Creates a new Port Mapping Property. Requires a specific parameter set to be passed as the new Port Mapping Property attributes.

```
POST /port_mapping_properties
```

Parameters:

+ `port_mapping_template_id` (required) - The ID of the Port Mapping Template which should acquire the new Port Mapping Property
+ `key` (required) - The exact key string, which will be recognized by property setting Atmosphere mechanism
+ `value` (optional) - The exact value to which the property key should be set

In case of successful Port Mapping Property creation, returns the JSON object with the details of the created entity.


## Update a Port Mapping Property

Updates the given Port Mapping Property. You need to be an Appliance Type owner (or an admin) do edit this entity.
Request parameters are the same as for `GET`ting a single Port Mapping Property.

```
PUT /port_mapping_properties/:id
```

Parameters:

+ `id` (required) - The ID of the Port Mapping Property to be updated
+ `key` (required) - The exact key string which will be recognized by the property-setting Atmosphere mechanism
+ `value` (optional) - The exact value to which the property key should be set

When a parameter is omitted, the value would be retained from the older version of the entity.


## Delete a Port Mapping Property

Deletes chosen Port Mapping Property. User deleting a Port Mapping Property has to be the owner of the parent Appliance Type or an admin.

```
DELETE /port_mapping_properties/:id
```

Parameters:

+ `id` (required) - The ID of the Port Mapping Property to be deleted
