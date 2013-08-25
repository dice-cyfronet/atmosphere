# http://emberjs.com/guides/models/defining-a-store/

App.Store = DS.Store.extend
  revision: 12
  adapter: "DS.FixtureAdapter" #DS.RESTAdapter.create()

App.ApplianceTypesRoute = Ember.Route.extend(
  model: ->
    App.ApplianceType.find()
)

App.ApplianceType = DS.Model.extend
  name: DS.attr("string")
  author: DS.attr("string")
  description: DS.attr("string")
  shared: DS.attr("boolean")
  scalable: DS.attr("boolean")
  visibility: DS.attr("string")

App.ApplianceType.FIXTURES = [ {
  id: 1,
  name: 'Ubuntu',
  author: 'Marek',
  description: '**Ubuntu** description',
  shared: true,
  scalable: false,
  visibility: 'published'
}, {
  id: 2,
  author: 'Tomek',
  name: 'Debian',
  description: '**Debian** description',
  shared: false,
  scalable: true,
  visibility: 'unpublished'
}, {
  id: 3,
  author: 'Piotrek',
  name: 'ArchLlinux',
  description: '**ArchiLinux** description',
  shared: true,
  scalable: true,
  visibility: 'unpublished'
}]
