App.ApplianceTypesRoute = Ember.Route.extend(
  model: ->
    App.ApplianceType.find()
)

App.IndexRoute = Ember.Route.extend(redirect: ->
  @transitionTo "appliance_types"
)