App.ApplianceTypesRoute = Ember.Route.extend
  model: ->
    this.store.find('appliance_type')

App.IndexRoute = Ember.Route.extend
  redirect: ->
    @transitionTo "appliance_types"