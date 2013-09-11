App.User = DS.Model.extend
  login: DS.attr('string')
  email: DS.attr('string')
  full_name: DS.attr('string')
  appliance_types: DS.hasMany('appliance_type', { inverse: 'author' })
  security_policies: DS.hasMany('security_proxy', { inverse: 'owners' })
  security_proxies: DS.hasMany('security_policy', { inverse: 'owners' })
