## List port mappings

Get a list of port mappings. A regular user only is allowed to see the  port mappings related to virtual machines assigned to owned appliances. Administrator is able to see all port mappings by adding query parameter `all` set to `true`.

```
GET /port_mappings
```

```json
{
  "port_mappings": [
    {
      "id": 1,
      "public_ip": "10.100.1.23",
      "source_port": 1234,
      "appliance_id": 1,
      "port_mapping_template_id": 1
    }, {
      ...
    }
  ]
}
```

## Details of a port mapping

Get all details of a port mapping.

```
GET /port_mappings/:id
```
Parameters:

+ `id` (required) - The ID of a port mapping

```json
{
  "port_mappings": {
    "id": 1,
    "public_ip": "10.100.1.23",
    "source_port": 1234,
    "appliance_id": 1,
    "port_mapping_template_id": 1
  }
}
```