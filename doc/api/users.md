## List registered users

Get a list of registered users. For normal `user` basic information is returned (login and full name), for `admin` full users details are returned if flag `all` is set to `true`.

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
      "email": "foobar@email.pl", #visible on for admin
      "roles": ["admin", "developer"], #visible only for admin
    }, {
      ...
    }
  ]
}
```

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
    "email": "foobar@email.pl", #visible on for admin
    "roles": ["admin", "developer"], #visible only for admin
  }
}
```