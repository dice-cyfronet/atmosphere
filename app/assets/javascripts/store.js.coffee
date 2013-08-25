# http://emberjs.com/guides/models/defining-a-store/

App.Store = DS.Store.extend
  revision: 12
  adapter: "DS.FixtureAdapter" #DS.RESTAdapter.create()