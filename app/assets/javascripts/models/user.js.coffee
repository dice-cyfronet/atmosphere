App.User = DS.Model.extend
  login: DS.attr('string')
  email: DS.attr('string')
  full_name: DS.attr('string')
  appliance_types: DS.hasMany('appliance_type')