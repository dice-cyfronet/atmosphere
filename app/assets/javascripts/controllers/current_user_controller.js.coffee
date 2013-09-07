App.CurrentUserController = Ember.ObjectController.extend
  isSignedIn: (->
    @get('content') != null
  ).property('@content')

  gravatar_url: (->
    Gravtastic(@get('content.email'), {default: 'mm', size: 17})
  ).property('@content.email')

  actions:
    logout: ->
      $.ajax
        type: 'DELETE',
        url: 'users/sign_out'
        success: ->
          document.location.reload(true)