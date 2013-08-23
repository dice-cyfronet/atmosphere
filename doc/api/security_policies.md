## List Security Policies

Get a list of security policies

```
GET /security_policies
```

```json
[
    {
        "name": "foobar/security/policy",
        "payload": "Security policy payload",
        "owners": ["marek", "tomek", "piotr"]
    }
]
```

```
GET /appliance_sets/:name
```

Parameters:

+ `name` (required) - The name of an security policy (can include `/`)

## New security policy

Creates a new security policy.

```
POST /security_policies
```

Parameters:

+ `name` (optional) - Security policy name (need to be globaly unique). It can be composed of letters, numbers, `-` and `_`
+ `payload` (optional) - Security policy payload
+ `owners` (optional) - List of security policy owners

## Update security policy

Update payload and list of security policy owners.

```
PUT /security_policies/:name
```

Parameters:

+ `name` (required) - The name of an security policy (can include `/`)
+ `payload` (optional) - New security policy payload
+ `owners` (optional) - New list of security policy owners

## Delete security policy

Delete security policy. User deleting security policy need to be its owner.

```
DELETE /security_policies/:name
```

Parameters:

+ `name` (required) - The name of an security policy (can include `/`)