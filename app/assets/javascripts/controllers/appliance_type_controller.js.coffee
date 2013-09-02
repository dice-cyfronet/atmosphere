App.ApplianceTypeController = Ember.ObjectController.extend(
  isEditing: false
  users: [{id: 1, login: 'marek'}, {id: 2, login: 'admin'}]

  actions:
    edit: ->
      @set "isEditing", true

    doneEditing: ->
      @set "isEditing", false

    delete: ->
      if (window.confirm("Are you sure you want to delete this post?"))
        @get('content').deleteRecord()
        @transitionToRoute('appliance_types')
)