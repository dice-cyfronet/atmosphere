## List compute sites

Get a list of registered compute sites. Normal user sees only basic information about compute site. Administrator additional is able to see compute site configuration.

```
GET /compute_sites
```

```json
{
  "compute_sites": [
    {
      "id": 1,
      "site_id":"cyfronet-folsom",
      "name":"Cyfronet",
      "location":"Cracow",
      "site_type":"private",
      "technology":"openstack",
      "config": "site specific config visible only for admin"
    }, {
      ...
    }
  ]
}
```

## Details of a compute site

Get all details of a compute site.

```
GET /compute_sites/:id
```

Parameters:

+ `id` (required) - The ID of a compute site.

```json
{
  "compute_sites":
  {
    "id": 1,
    "site_id":"cyfronet-folsom",
    "name":"Cyfronet",
    "location":"Cracow",
    "site_type":"private",
    "technology":"openstack",
    "config": "site specific config visible only for admin"
  }
}
```