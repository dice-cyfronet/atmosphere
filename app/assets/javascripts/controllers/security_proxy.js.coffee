### Security Proxies ###
App.SecurityProxiesController = Ember.ArrayController.extend
  sortProperties: ['name']
  sortAscending: true

  filteredContent: (->
    @filter (item, index) ->
      not (item.get("isNew"))
  ).property("@each.isNew")

App.SecurityProxiesNewController = Ember.ObjectController.extend
  isEditing: true

  actions:
    save: ->
      @get('content').save().then (security_proxy) =>
        @transitionToRoute('security_proxy', appliance_type)

    cancel: ->
      @get('content').deleteRecord()
      @transitionToRoute('security_proxies')

### Security Proxy ###
App.SecurityProxyController = Ember.ObjectController.extend
  isEditing: false

  actions:
    edit: ->
      @set 'isEditing', true

    doneEditing: ->
      @get('content').save().then (security_proxy) =>
        @set 'isEditing', false

    cancelEditing: ->
      @get('content').rollback()
      @set 'isEditing', false

    delete: ->
      if (window.confirm('Are you sure you want to delete this security proxy?'))
        @get('content').deleteRecord()
        @get('content').save().then =>
          @transitionToRoute('security_proxies')