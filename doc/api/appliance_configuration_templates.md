## List appliance configuration templates

Get list of all available appliance configuration templates. By available appliance configuration templates we understand configuration templates from all appliance types belonging to the user, plus all configuration templates from `published` appliance types. Admin is able to browse information about all appliance types configuration templates by setting flag `all` into `true`. Additionally there is possibility to limit amount of returned appliance configuration templates by defining filters.


Appliance configuration template can contains `static` or `dynamic` payload. List of dynamic variable names are available in `properties` table. While starting new appliance type user can inject values of the properties (see [adding new appliance into appliance set](appliances#post) section for more details).

```
GET /appliance_configuration_templates
```

```json
{
  "appliance_configuration_templates": [
    {
      "id": 1,
      "name": "Foobar appliance configuration template",
      "payload": "Fobar appliance configuration template payload without dynamic payload",
      "properties": []
      "appliance_type_id": 2
    }, {
      ...
    }
  ]
}
```

## Details of an appliance configuration template

Get all details of an appliance configuration template.

```
GET /appliance_configuration_templates/:id
```

Parameters:

+ `id` (required) - The ID of an appliance configuration template

```json
{
  "appliance_configuration_template": {
    "id": 1,
    "name": "Foobar appliance configuration template",
    "payload": "Fobar appliance configuration template payload with #{dynamic} #{payload}",
    "properties": ["dynamic", "payload"]
    "appliance_type_id": 2
  }
}
```

## New appliance configuration template

Creates a new appliance configuration template. Normal user is able to create new appliance configuration template only for owned appliance type (where user is an appliance type author), admin is able to create appliance configuration template for all appliance types.

```
POST /appliance_configuration_templates
```

Parameters:

+ `name` (optional) - Appliance configuration template name
+ `payload` (optional) - Appliance configuration template payload. It can contain placeholders (aka. dynamic variables in `#{variable_name}` format) for dynamic configuration. If such placeholder occurs than during appliance instantiation user can pass variables values. If variable is not found in instantiation request than empty string will be injected there
+ `appliance_type_id` - appliance type id for which this appliance configuration template will be created

Special dynamic parameters which are automaticaly converted into dynamic values:

+ `#{mi_ticket} - While creating initial configuration instance user ticket is injected here

## Update appliance configuration template

Updates existing appliance configuration template. Normal user is able to update appliance configuration template only for owned appliance type (where user is an appliance type author), admin is able to update appliance configuration template for all appliance types.

```
PUT /appliance_configuration_templates/:id
```

Parameters:

+ `id` (required) - The ID of an appliance configuration template
+ `name` (optional) - Updated appliance configuration template name
+ `payload` (optional) - Updated appliance configuration template payload. It can contain placeholders (aka. dynamic variables in `#{variable_name}` format) for dynamic configuration. If such placeholder occurs than during appliance instantiation user can pass variables values. If variable is not found in instantiation request than empty string will be injected there

## Delete appliance configuration template

Deletes existing appliance configuration template. Normal user is able to delete only appliance configuration templates from owned appliance types (where user is an appliance type author), admin is able to delete all appliance configuration templates.

```
DELETE /appliance_configuration_templates/:id
```

Parameters:

+ `id` (required) - The ID of an appliance configuration template