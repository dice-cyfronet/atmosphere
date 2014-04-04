## List http mappings

Get a list of http mappings. A regular user is allowed to see only http mappings related to their own appliances. Administrator is able to see all http mappings by adding query parameter `all` set to `true`.

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
            "port_mapping_template_id": 11,
            "monitoring_status": "ok"
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
            "port_mapping_template_id": 13,
            "monitoring_status": "pending"
        }
}
```

`monitoring_status` is a field set by the endpoint monitoring system. It has following possible values:
+ `pending` - initial state after appliance is started. It means that appliance is starting and this endpoint is not reachable yet.
+ `ok` - endpoint is reachable
+ `lost` - endpoint was `ok` but right now it is unreachable
+ `not_monitored` - endpoint is not monitored
