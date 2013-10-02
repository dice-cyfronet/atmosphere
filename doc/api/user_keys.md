## List of owned user keys

Get list of all keys belonging to current user. For normal user only owned keys are turned, admin is able to set flag `all` into `true` (e.g. by adding `?all=true` to the request path) and thus receive list of all users keys.

```
GET /user_keys
```

```json
{
  "user_keys": [
    {
      "id": 1,
      "name": "Fobar key",
      fingerprint: "43:c5:5b:5f:b1:f1:50:43:ad:20:a6:92:6a:1f:9a:3a",
      public_key: "ssh-rsa ....",
      user_id: 1
    }, {
      ...
    }
  ]
}
```

## Details of an user key

```
GET /user_keys/:id
```

Parameters:

+ `id` (required) - The ID of an user key

```json
{
  "user_key": {
    "id": 1,
    "name": "Fobar key",
    fingerprint: "43:c5:5b:5f:b1:f1:50:43:ad:20:a6:92:6a:1f:9a:3a",
    public_key: "ssh-rsa ....",
    user_id: 1
  }
}
```

## New user key

Creates new user key.

```
POST /user_keys
```

```json
{
  "user_key": {
    "name": "Fobar key",
    public_key: "ssh-rsa ....",
  }
}
```

Parameters:

+ `name` (required) - User key name
+ `public_key` - Public key payload

## Delete user key

Normal user is able to remove only owned user keys. Admin is able to remove any user key.

```
DELETE /user_keys/:id
```

Parameters:

+ `id` (required) - The ID of an user key