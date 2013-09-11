### Security policies ###
App.SecurityPoliciesRoute = Ember.Route.extend
  model: ->
    this.store.find('security_policy')

App.SecurityPoliciesNewRoute = Ember.Route.extend
  model: ->
    this.store.createRecord('security_policy')

### Security policy ###
App.SecurityPolicyRoute = Ember.Route.extend
  setupController: (controller, model)->
    controller.set('isEditing', false)
    controller.set('model', model)
