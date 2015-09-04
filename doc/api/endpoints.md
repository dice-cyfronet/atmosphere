## List Endpoints

Get a list of Endpoints defined for a given Port Mapping Template.

```
GET /endpoints
```

```json
{
  "endpoints": [
    {
      "id": 1,
      "name": "name of the endpoint",
      "description": "some descriptive text",
      "descriptor": "<xml>structured_text_for_machine_use</xml>" (e.g., a WSDL document),
      "endpoint_type": one of "rest", "ws" or "webapp",
      "invocation_path": "app/invocation/path",
      "port_mapping_template_id": 5 (should equal the :port_mapping_template_id parameter),
      "secured": true/false
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
  "name": "name of the endpoint",
  "description": "some descriptive text",
  "descriptor": "<xml>structured_text_for_machine_use</xml>" (e.g., a WSDL document),
  "endpoint_type": one of "rest", "ws" or "webapp",
  "invocation_path": "app/invocation/path",
  "port_mapping_template_id": 5,
  "secured": true
}
```


## Create a Endpoint

Creates a new Endpoint. Requires a specific parameter set to be passed as the new Endpoint attributes.

```
POST /endpoints
```

Parameters:

+ `port_mapping_template_id` (required) - The ID of the Port Mapping Template which should acquire the new Endpoint
+ `name` (required) - Short name of the endpoint meaning and purpose
+ `description` (optional) - Textual, human-readable description what is available on the given port
+ `descriptor` (optional) - Machine-readable document that describes the service available on the given port. It supports one dynamic parameter: `#{descriptor_url}`. When included in descriptor payload, this parameter will be automatically swapped for the actual endpoint URL.
+ `endpoint_type` (optional) - Choose "rest", "ws" or "webapp"
+ `invocation_path` (required) - Application invocation path
+ `secured` (optional) - True if endpoint is secured and require user token (default `false`)

In case of successful Endpoint creation, returns the JSON object with the details of the created entity.


## Update a Endpoint

Updates the given Endpoint. You need to be an Appliance Type owner (or an admin) do edit this entity.
Request parameters are the same as for `GET`ting a single Endpoint.

```
PUT /endpoints/:id
```

Parameters:

+ `id` (required) - The ID of the Endpoint to be updated
+ `name` (optional) - Short name of the endpoint meaning and purpose
+ `description` (optional) - Textual, human-readable description of what is available on the given port
+ `descriptor` (optional) - Machine-readable document that describes the service available on the given port. It supports one dynamic parameter: `#{descriptor_url}`. When included in descriptor payload, this parameter will be automatically swapped for the actual endpoint URL.
+ `endpoint_type` (optional) - Choose "rest", "ws" or "webapp"
+ `invocation_path` (optional) - Application invocation path
+ `secured` (optional) - True if endpoint is secured and requires user token (default `false`)

When a parameter is omitted, the value would be retained from the older version of the entity.


## Delete a Endpoint

Deletes chosen Endpoint. User deleting a Endpoint has to be the owner of the parent Appliance Type or an admin.

```
DELETE /endpoints/:id
```

Parameters:

+ `id` (required) - The ID of the Endpoint to be deleted

## Get endpoint descriptor

Method used by Taverna to include endpoint descriptor (WSDL or WADL) into Taverna workbench. If `#{descriptor_url}` parameter is available in the descriptor payload than it is converted into actual enpoint url.

When user credentials are empty this method will return success only for Appliance Types with `visible_to` set to `all` endpoints. If user credentials are available than user is able to get endpoint descriptor for Appliance Types with `visible_to` set to `owner` or `developer` (if user is a developer).

```
GET /endpoints/:id/descriptor
```

+ `id` (required) - The ID of an endpoint
