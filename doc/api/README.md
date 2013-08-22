# AIR API

All API requests require authentication (if not stated different). You need to pass a `private_token` parameter by url or header. If passed as header, the header name must be "PRIVATE-TOKEN" (capital and with dash instead of underscore).

If no, or an invalid, `private_token` is provided then an error message will be returned with status code 401:

```json
{
  "message": "401 Unauthorized"
}
```

API requests should be prefixed with `api` and the API version. Current API version is equals to `v1`

Example of a valid API request:

```
GET http://example.com/api/v1/appliance_sets?private_token=FSGa2df2gSdfg
```

Example for a valid API request using curl and authentication via header:

```
curl --header "PRIVATE-TOKEN: FSGa2df2gSdfg" "http://example.com/api/v1/appliance_sets"
```

## Status codes

`FIXME`

## Contents

+ [Appliance Sets](appliance_sets)
+ [Security Proxies](security_proxies)
+ [Security Policies](security_policies)
