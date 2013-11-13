## List Port Mapping Templates

Get a list of Port Mapping Templates defined for a given Appliance Type.

```
GET /port_mapping_templates
```

Parameters:

+ `appliance_type_id` (required) - The ID of the appliance type which Port Mapping Templates you'd like to get

```json
{
  "port_mapping_templates": [
    {
      "id": 1,
      "transport_protocol": either "tcp" or "udp",
      "application_protocol": one of "http", "https", "http_https" or "none" (when "transport_protocol" is "udp"),
      "service_name": "rdesktop",
      "target_port": 3389,
      "appliance_type_id": 5 (should equal the :appliance_type_id parameter)
    }, {
      ...
    }
  ]
}
```


## Details of a Port Mapping Template

Get the full JSON document about a given Port Mapping Template.

```
GET /port_mapping_templates/:id
```

Parameters:

+ `id` (required) - The ID of the Port Mapping Template you are interested in

```json
{
  "id": 1 (should equal the :id parameter),
  "transport_protocol": either "tcp" or "udp",
  "application_protocol": one of "http", "https", "http_https" or "none" (when "transport_protocol" is "udp"),
  "service_name": "rdesktop",
  "target_port": 3389,
  "appliance_type_id": 5
}
```


## Create a Port Mapping Template

Creates a new Port Mapping Template. Requires a specific parameter set to be passed as the new Port Mapping
Template attributes.

```
POST /port_mapping_templates
```

Parameters:

+ `appliance_type_id` (required) - The ID of the Appliance Type which should acquire the new port mapping template
+ `transport_protocol` (required) - What transport protocol the port operates, the value should be either "tcp" or "udp"
+ `application_protocol` (required) - If using TCP transport protocol, choose one of "http", "https", "http_https". Use "none" for UDP
+ `service_name` (required) - Some kind of descriptive name for the service operating on that port
+ `target_port` (required) - The port number

In case of successful Port Mapping Template creation, returns the JSON object with the details of the created entity.


## Update a Port Mapping Template

Updates the given Port Mapping Template. You need to be an Appliance Type owner (or an admin) do edit this entity.

```
PUT /port_mapping_templates/:id
```

Parameters:

+ `id` (required) - The ID of the Port Mapping Template to be updated
+ All other parameters are optional and are the same as for the `POST` creation method

When a parameter is omitted, the value would be retained from the older version of the entity. However, keep in mind
the application and transport protocol constraints when updating these values.


## Delete a Port Mapping Template

Deletes chosen Port Mapping Template. User deleting a Port Mapping Template has to be its owner or an admin.

```
DELETE /port_mapping_templates/:id
```

Parameters:

+ `id` (required) - The ID of the Port Mapping Template to be deleted
