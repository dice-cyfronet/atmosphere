## List registered users

Get a list of registered users. For normal users only basic information is returned (login and full name), while admins can obtain full user details if the `all` flag is set to `true`.

```
GET /users
```

```json
{
  "users": [
    {
      "id": 1,
      "login": "foo",
      "full_name": "Foo Bar",
      "email": "foobar@email.pl",
      "roles": ["admin", "developer"]
    }, {
      ...
    }
  ]
}
```

*Note:* `email` and `roles` fields are added only in two cases:
  * request is made by the admin, then all users details are returned
  * details are returned only for record representing user who pefromed request

## Details of a user

Get all details of a user.

```
GET /users/:id
```

Parameters:

+ `id` (required) - The ID of a user

```json
{
  "user": {
    "id": 1,
    "login": "foo",
    "full_name": "Foo Bar",
    "email": "foobar@email.pl",
    "roles": ["admin", "developer"]
  }
}
```