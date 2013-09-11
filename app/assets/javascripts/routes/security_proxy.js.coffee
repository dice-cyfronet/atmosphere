### Security proxies ###
App.SecurityProxiesRoute = Ember.Route.extend
  model: ->
    this.store.find('security_proxy')

App.SecurityProxiesNewRoute = Ember.Route.extend
  model: ->
    this.store.createRecord('security_proxy')

### Security proxy ###