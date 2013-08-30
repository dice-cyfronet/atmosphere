App.ApplianceType = DS.Model.extend
  name: DS.attr('string')
  description: DS.attr('string')
  shared: DS.attr('boolean')
  scalable: DS.attr('boolean')
  visibility: DS.attr('string')
  author: DS.belongsTo('App.User')