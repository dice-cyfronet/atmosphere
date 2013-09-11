App.FilteredContentController = Ember.ArrayController.extend
  filteredContent: (->
    @filter (item, index) ->
      not (item.get("isNew"))
  ).property("@each.isNew")

App.NewContentController = Ember.ObjectController.extend
  isEditing: true

  actions:
    save: ->
      @get('content').save().then (item) =>
        @transitionToRoute(@get('contentType'), item)

    cancel: ->
      @get('content').deleteRecord()
      @transitionToRoute(@get('indexRoute'))

App.EditDeleteContentController = Ember.ObjectController.extend
  isEditing: false

  actions:
    edit: ->
      @set 'isEditing', true

    doneEditing: ->
      @get('content').save().then (item) =>
        @set 'isEditing', false

    cancelEditing: ->
      @get('content').rollback()
      @set 'isEditing', false

    delete: ->
      if (window.confirm('Are you sure you want to delete this %@?'.fmt(@get('contentType').classify())))
        @get('content').deleteRecord()
        @get('content').save().then =>
          @transitionToRoute(@get('indexRoute'))
