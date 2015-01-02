## List information about appliance types endpoints

Get list of appliance types with endpoints. You can limit number of appliance types and endpoints returned by filtering endpoint type or providing endpoint ids.

```
GET /appliance_endpoints
GET /appliance_endpoints?endpoint_type=ws (rest or webapp)
GET /appliance_endpoints?endpoint_type=ws,rest
GET /appliance_endpoints?endpoint_id=1,3,7
```

```json
{
  "appliance_endpoints": [
    {
      "id": 1,
      "name": "Foobar Appliance Type",
      "description": "Foobar Appliance Type description",
      "endpoints": [
        {
          "id": 1,
          "name": "name of the endpoint",
          "description": "some descriptive text",
          "endpoint_type": "ws", ("rest" or "webapp")
          "url": "url_to_descriptor"
        }, ...
      ]
    }, {
      ...
    }
  ]
}
```