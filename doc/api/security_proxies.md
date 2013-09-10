## List Security Proxies

Get a list of security proxies

```
GET /security_proxies
```

```json
{
  "security_proxies": [
    {
      "name": "foobar/security/proxy",
      "payload": "Security proxy payload",
      "owners": [1, 2, 3]
    }, {
      ...
    }
  ]
}
```

## Details of an security proxy

Get all details of a security proxy.

```
GET /security_proxies
```

Parameters:

+ `id` (required) - The ID of a security proxy

```json
{
  "security_proxy": [
    {
      "name": "foobar/security/proxy",
      "payload": "Security proxy payload",
      "owners": [1, 2, 3]
    }
  ]
}
```

## New security proxy

Creates a new security proxy. Request format is the same as `GET` single security proxy response.

```
POST /security_proxies
```

Parameters:

+ `name` (required) - Security proxy name (need to be globaly unique). It can be composed of letters, numbers, `/`, `-` and `_`
+ `payload` (required) - Security proxy payload
+ `owners` (optional) - List of security proxy owners. If this list is empty than current user is set as security proxy owner.

## Update security proxy

Update security proxy. You need to be an appliance type owner (or admin) do edit this entity. Request format is the same as `GET` single security proxy response.

```
PUT /security_proxies/:id
```

Parameters:

+ `id` (required) - The ID of a security proxy
+ All other parameters are optional and are the same as for `POST` method

## Delete security proxy

Delete security proxy. User deleting security proxy need to be its owner.

```
DELETE /security_proxies/:id
```

Parameters:

+ `id` (required) - The ID of a security proxy

## Get security proxy payload

Get security proxy payload as plain text

```
GET /security_proxies/:name/payload
```

Parameters:

+ `name` (required) - The name of an security proxy (can include `/`)