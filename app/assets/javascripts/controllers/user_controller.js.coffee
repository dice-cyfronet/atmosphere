### Users ###
App.UsersController = Ember.ArrayController.extend
  sortProperties: ['full_name']
  sortAscending: false


### User ###
App.UserController = Ember.ObjectController.extend
  isEditing: false

  actions:
    edit: ->
      @set 'isEditing', true

    delete: ->
      if (window.confirm('Are you sure you want to delete this user?'))
        @get('content').deleteRecord()
        @get('content').save().then =>
          @transitionToRoute('users')