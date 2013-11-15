## List Endpoints

Get a list of Endpoints defined for a given Port Mapping Template.

```
GET /endpoints
```

Parameters:

+ `port_mapping_template_id` (required) - The ID of the specific Port Mapping Template which Endpoints you'd like to get

```json
{
  "endpoints": [
    {
      "id": 1,
      "description": "some descriptive text",
      "descriptor": "<xml>structured_text_for_machine_use</xml>" (e.g., a WSDL document),
      "endpoint_type": one of "rest", "ws" or "webapp",
      "invocation_path": "app/invocation/path",
      "port_mapping_template_id": 5 (should equal the :port_mapping_template_id parameter)
    }, {
      ...
    }
  ]
}
```


## Details of a Endpoint

Get the full JSON document about a given Endpoint.

```
GET /endpoints/:id
```

Parameters:

+ `id` (required) - The ID of the Endpoint you are interested in

```json
{
  "id": 1 (should equal the :id parameter),
  "description": "some descriptive text",
  "descriptor": "<xml>structured_text_for_machine_use</xml>" (e.g., a WSDL document),
  "endpoint_type": one of "rest", "ws" or "webapp",
  "invocation_path": "app/invocation/path",
  "port_mapping_template_id": 5
}
```


## Create a Endpoint

Creates a new Endpoint. Requires a specific parameter set to be passed as the new Endpoint attributes.

```
POST /endpoints
```

Parameters:

+ `port_mapping_template_id` (required) - The ID of the Port Mapping Template which should acquire the new Endpoint
+ `description` (optional) - Textual, human-readable description what is available on that port
+ `descriptor` (optional) - Machine-readable document that describes the service available on that port
+ `endpoint_type` (required) - One of "rest", "ws" or "webapp"
+ `invocation_path` (required) - Application invocation path

In case of successful Endpoint creation, returns the JSON object with the details of the created entity.


## Update a Endpoint

Updates the given Endpoint. You need to be an Appliance Type owner (or an admin) do edit this entity.
Request parameters are the same as for `GET`ting a single Endpoint.

```
PUT /endpoints/:id
```

Parameters:

+ `id` (required) - The ID of the Endpoint to be updated
+ All other parameters are optional and are the same as for the `POST` creation method

When a parameter is omitted, the value would be retained from the older version of the entity.


## Delete a Endpoint

Deletes chosen Endpoint. User deleting a Endpoint has to be the owner of the parent Appliance Type or an admin.

```
DELETE /endpoints/:id
```

Parameters:

+ `id` (required) - The ID of the Endpoint to be deleted
