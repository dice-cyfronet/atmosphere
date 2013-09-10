## List Security Policies

Get a list of security policies

```
GET /security_policies
```

```json
{
  "security_policies": [
    {
      "name": "foobar/security/policy",
      "payload": "Security policy payload",
      "owners": [1, 2, 3]
    }, {
      ...
    }
  ]
}
```

## Details of an security policy

Get all details of a security policy.

```
GET /security_policies
```

Parameters:

+ `id` (required) - The ID of a security policy

```json
{
  "security_policy": [
    {
      "name": "foobar/security/policy",
      "payload": "Security policy payload",
      "owners": [1, 2, 3]
    }
  ]
}
```

## New security policy

Creates a new security policy. Request format is the same as `GET` single security policy response.

```
POST /security_policies
```

Parameters:

+ `name` (required) - Security policy name (need to be globaly unique). It can be composed of letters, numbers, `/`, `-` and `_`
+ `payload` (required) - Security policy payload
+ `owners` (optional) - List of security policy owners. If this list is empty than current user is set as security policy owner.

## Update security policy

Update security policy. You need to be an appliance type owner (or admin) do edit this entity. Request format is the same as `GET` single security policy response.

```
PUT /security_policies/:id
```

Parameters:

+ `id` (required) - The ID of a security policy
+ All other parameters are optional and are the same as for `POST` method

## Delete security policy

Delete security policy. User deleting security policy need to be its owner.

```
DELETE /security_policies/:id
```

Parameters:

+ `id` (required) - The ID of a security policy

## Get security policy payload

Get security policy payload as plain text

```
GET /security_policies/:name/payload
```

Parameters:

+ `name` (required) - The name of an security policy (can include `/`)