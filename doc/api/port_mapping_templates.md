## List Port Mapping Templates

Get a list of Port Mapping Templates defined for a given Appliance Type (or a given Dev Mode Property Set, when
used in the development mode).

```
GET /port_mapping_templates
```

Parameters (one of the following is required):

+ `appliance_type_id` - The ID of the appliance type which Port Mapping Templates you'd like to get
+ `dev_mode_property_set_id` - The ID of the Development Mode Property Set of an Appliance, which Port Mapping Templates you'd like to get

```json
{
  "port_mapping_templates": [
    {
      "id": 1,
      "transport_protocol": either "tcp" or "udp",
      "application_protocol": one of "http", "https" or "none" (when "transport_protocol" is "udp"),
      "service_name": "rdesktop",
      "target_port": 3389,
      "appliance_type_id": 5 or nil (should equal the :appliance_type_id parameter)
      "dev_mode_property_set_id": 5 or nil (should equal the :dev_mode_property_set_id parameter)
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
  "port_mapping_template": {
    "id": 1 (should equal the :id parameter),
    "transport_protocol": either "tcp" or "udp",
    "application_protocol": one of "http", "https" or "none" (when "transport_protocol" is "udp"),
    "service_name": "rdesktop",
    "target_port": 3389,
    "appliance_type_id": 5 or nil,
    "dev_mode_property_set_id": 5 or nil
  }
}
```


## Create a Port Mapping Template

Creates a new Port Mapping Template. Requires a specific parameter set to be passed as the new Port Mapping
Template attributes.

```
POST /port_mapping_templates
```

Parameters (one of the first two is required):

+ `appliance_type_id` - The ID of the Appliance Type which should acquire the new port mapping template
+ `dev_mode_property_set_id` - The ID of the Dev Mode Property Set which should acquire the new port mapping template
+ `transport_protocol` (required) - The transport protocol operated by the given port. The value should be either "tcp" or "udp".
+ `application_protocol` (required) - When using the TCP transport protocol, choose "http", "https" or "none". Use "none" for UDP connections.
+ `service_name` (required) - Descriptive name of the service operating at the given port
+ `target_port` (required) - Port number

In case of successful Port Mapping Template creation, returns the JSON object with the details of the created entity.


## Update a Port Mapping Template

Updates the given Port Mapping Template. You need to be an Appliance Type owner (or an admin) do edit this entity.
In case of the development mode use, you need to be the owner of the Appliance Set being run.

```
PUT /port_mapping_templates/:id
```

Parameters:

+ `id` (required) - The ID of the Port Mapping Template to be updated
+ `transport_protocol` (required) - The transport protocol operated by the given port. The value should be either "tcp" or "udp".
+ `application_protocol` (required) - When using the TCP transport protocol, choose "http", "https" or "none". Use "none" for UDP connections.
+ `service_name` (required) - Descriptive name of the service operating at the given port
+ `target_port` (required) - Port number

When a parameter is omitted, the value would be retained from the older version of the entity. However, keep in mind
the application and transport protocol constraints when updating these values.


## Delete a Port Mapping Template

Deletes chosen Port Mapping Template. User deleting a Port Mapping Template has to be its owner or an admin.

```
DELETE /port_mapping_templates/:id
```

Parameters:

+ `id` (required) - The ID of the Port Mapping Template to be deleted
