### Appliance types ###
App.ApplianceTypesRoute = Ember.Route.extend
  model: ->
    this.store.find('appliance_type')

App.ApplianceTypesNewRoute = Ember.Route.extend
  model: ->
    this.store.createRecord('appliance_type')


### Appliance type ###
App.ApplianceTypeRoute = Ember.Route.extend
  setupController: (controller, model)->
    controller.set('isEditing', false)
    controller.set('model', model)
    this.store.find('user').then (users)->
      controller.set('users', users)
