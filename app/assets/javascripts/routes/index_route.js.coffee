App.IndexRoute = Ember.Route.extend
  redirect: ->
    @transitionTo 'appliance_types'