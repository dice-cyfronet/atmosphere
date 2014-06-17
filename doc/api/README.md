<!--- This section is copied from: https://raw.github.com/gitlabhq/gitlabhq/master/doc/api/README.md -->

# AIR API

All API requests require authentication (if not stated different). You need to pass a `private_token` or `mi_ticket` parameter by url or header.

If no, or an invalid, `private_token` or `mi_ticket` is provided then an error message will be returned with status code 401:

```json
{
  "message": "401 Unauthorized"
}
```

API requests should be prefixed with `api` and the API version. Current API version is equals to `v1`

Example of a valid API request:

```
GET http://example.com/api/v1/appliance_sets?private_token=FSGa2df2gSdfg
GET http://example.com/api/v1/appliance_sets?mi_ticket=fd342hac4a=
```

Example for a valid API request using curl and authentication via header:

```
curl --header "PRIVATE-TOKEN: QVy1PB7sTxfy4pqfZM1U" http://example.com/api/v1/appliance_sets
curl --header "MI-TICKET: fd342hac4a=" http://example.com/api/v1/appliance_sets
```

## Status codes

The API is designed to return different status codes according to context and action. In this way if a request results in an error the caller is able to get insight into what went wrong, e.g. status code `422 Unprocessable Entity` is returned if a required attribute is missing from the request. The following list gives an overview of how the API functions generally behave.

API request types:

* `GET` requests access one or more resources and return the result as JSON. Objects array with root equals into resource name (e.g. `appliance_types` for listing all appliance types and `appliance_type` for getting single appliance type) is returned
* `POST` requests return `201 Created` if the resource is successfully created and return the newly created resource as JSON
* `POST` and `PUT` request bodies format needs to the same format as for getting single resource response
* `GET`, `PUT` and `DELETE` return `200 Ok` if the resource is accessed, modified or deleted successfully, the (modified) result is returned as JSON

The following list shows the possible return codes for API requests.

Return values:

* `200 Ok` - The `GET`, `PUT` or `DELETE` request was successful, the resource(s) itself is returned as JSON
* `201 Created` - The `POST` request was successful and the resource is returned as JSON
* `400 Bad Request` - The request cannot be fulfilled due to bad syntax.
* `401 Unauthorized` - The user is not authenticated, a valid user token is necessary, see above
* `403 Forbidden` - The request is not allowed, e.g. the user is not allowed to delete an appliance type
* `404 Not Found` - A resource could not be accessed, e.g. an ID for a resource could not be found
* `405 Method Not Allowed` - The request is not supported
* `409 Conflict` - A conflicting resource already exists, e.g. creating a appliance type with a name that already exists
* `422 Unprocessable Entity` - A required attribute of the API request is missing or in wrong format, e.g. the name of an appliance type is not given
* `500 Server Error` - While handling the request something went wrong on the server side

## Sudo

If you are an admin of the system, than you are able to sudo as other user. To do so simply add `sudo=other_user_name` into request query params. E.g.:

```
GET http://example.com/api/v1/appliance_sets?private_token=FSGa2df2gSdfg&sudo=other_user
GET http://example.com/api/v1/appliance_sets?mi_ticket=fd342hac4a=&sudo=other_user
```

```
curl --header "PRIVATE-TOKEN: QVy1PB7sTxfy4pqfZM1U" http://example.com/api/v1/appliance_sets?sudo=other_user
curl --header "MI-TICKET: fd342hac4a=" http://example.com/api/v1/appliance_sets?sudo=other_user
```