## List Security Proxies

Get a list of security proxies

```
GET /security_proxies
```

```json
[
    {
        "name": "foobar/security/proxy",
        "payload": "Security proxy payload",
        "owners": ["marek", "tomek", "piotr"]
    }
]
```

```
GET /appliance_sets/:name
```

Parameters:

+ `name` (required) - The name of an security proxy (can include `/`)

## New security proxy

Creates a new security proxy.

```
POST /security_proxies
```

Parameters:

+ `name` (optional) - Security proxy name (need to be globaly unique). It can be composed of letters, numbers, `-` and `_`
+ `payload` (optional) - Security proxy payload
+ `owners` (optional) - List of security proxy owners

## Update security proxy

Update payload and list of security proxy owners.

```
PUT /security_proxies/:name
```

Parameters:

+ `name` (required) - The name of an security proxy (can include `/`)
+ `payload` (optional) - New security proxy payload
+ `owners` (optional) - New list of security proxy owners

## Delete security proxy

Delete security proxy. User deleting security proxy need to be its owner.

```
DELETE /security_proxies/:name
```

Parameters:

+ `name` (required) - The name of an security proxy (can include `/`)