App.SecurityPolicy = DS.Model.extend
  name: DS.attr('string')
  payload: DS.attr('string')
  owners: DS.hasMany('user')