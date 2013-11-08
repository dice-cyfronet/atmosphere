## List http mappings

Get a list of http mappings. A regular user only is allowed to see the the appliances related to their own appliances.

```
GET /http_mappings
```

```json
{
    "http_mappings": [
        {
            "id": 11,
            "application_protocol": "http",
            "url": "conn.ca",
            "appliance_id": 11,
            "port_mapping_template_id": 11
        },
        ...
    ]
}
```

## Details of a http mapping

Get all details of a http mapping.

```
GET /http_mappings/:id
```
Parameters:

+ `id` (required) - The ID of a http mapping

```json
{
    "http_mapping":
        {
            "id": 13,
            "application_protocol": "http",
            "url": "jacobson.co.uk",
            "appliance_id": 13,
            "port_mapping_template_id": 13
        }
}
```
