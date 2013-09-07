Ember.Application.initializer
  name: 'currentUser'

  initialize: (container) ->
    store = container.lookup('store:main')
    attributes = $('meta[name="current-user"]').attr('content')

    if attributes
      object = store.push('user', JSON.parse(attributes))
      user = store.find('user', object.id)

      controller = container.lookup('controller:currentUser').set('content', user)

      container.typeInjection('controller', 'currentUser', 'controller:currentUser')