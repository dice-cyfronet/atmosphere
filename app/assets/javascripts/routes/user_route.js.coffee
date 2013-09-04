### Users ###
App.UsersRoute = Ember.Route.extend
  model: ->
    this.store.find('user')


### User ###
App.UserRoute = Ember.Route.extend
  setupController: (controller, model)->
    controller.set('isEditing', false)
    controller.set('model', model)