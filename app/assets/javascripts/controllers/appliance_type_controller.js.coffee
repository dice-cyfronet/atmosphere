App.ApplianceTypeController = Ember.ObjectController.extend
  isEditing: false
  visibilities: ['unpublished', 'published']

  actions:
    edit: ->
      @set 'isEditing', true

    doneEditing: ->
      @get('content').save().then (appliance_type)=>
        @set 'isEditing', false

    delete: ->
      if (window.confirm('Are you sure you want to delete this post?'))
        @get('content').deleteRecord()
        @get('content').save().then =>
          @transitionToRoute('appliance_types')

App.ApplianceTypesNewController = Ember.ObjectController.extend
  visibilities: ['unpublished', 'published']

  actions:
    save: ->
      @get('content').save().then (appliance_type)=>
        @transitionToRoute('appliance_type', appliance_type)

    cancel: ->
      @get('content').deleteRecord()
      @transitionToRoute('appliance_types')

App.ApplianceTypesController = Ember.ArrayController.extend
  sortProperties: ['name']
  sortAscending: true
