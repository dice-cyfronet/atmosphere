## List of owned user keys

Get list of all keys belonging to current user. For normal user only owned keys are returned; an admin is able to set the `all` flag to `true` (e.g. by adding `?all=true` to the request path) and thus receive a list of all keys.

```
GET /user_keys
```

```json
{
  "user_keys": [
    {
      "id": 1,
      "name": "Fobar key",
      "fingerprint": "43:c5:5b:5f:b1:f1:50:43:ad:20:a6:92:6a:1f:9a:3a",
      "public_key": "ssh-rsa ....",
      "user_id": 1
    }, {
      ...
    }
  ]
}
```

## Details of a user key

```
GET /user_keys/:id
```

Parameters:

+ `id` (required) - The ID of a user key

```json
{
  "user_key": {
    "id": 1,
    "name": "Fobar key",
    "fingerprint": "43:c5:5b:5f:b1:f1:50:43:ad:20:a6:92:6a:1f:9a:3a",
    "public_key": "ssh-rsa ....",
    "user_id": 1
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
    "public_key": "ssh-rsa ....",
  }
}
```

Parameters:

+ `name` (required) - User key name
+ `public_key` - Public key payload or the uploaded user file with the contents of the key inside it


## Delete user key

Normal user is able to remove only owned keys. An admin is able to remove any user key.

```
DELETE /user_keys/:id
```

Parameters:

+ `id` (required) - The ID of a user key