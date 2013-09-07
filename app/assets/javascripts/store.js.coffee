App.Store = DS.Store.extend
  adapter: 'DS.RESTAdapter'

DS.RESTAdapter.reopen
  namespace: 'api/v1'