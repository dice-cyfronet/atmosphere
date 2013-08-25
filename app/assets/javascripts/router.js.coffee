# For more information see: http://emberjs.com/guides/routing/

App.Router.map ()->
  @resource('about')
  @resource "appliance_types", ->
    @resource "appliance_type",
      path: ":appliance_type_id"
    @route "new"

App.ApplianceTypesRoute = Ember.Route.extend(
  model: ->
    App.ApplianceType.find()
)