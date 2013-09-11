### Appliance types ###
App.ApplianceTypesController = App.FilteredContentController.extend
  sortProperties: ['name']
  sortAscending: true


App.ApplianceTypesNewController = App.NewContentController.extend
  visibilities: ['unpublished', 'published']
  contentType: 'appliance_type'
  indexRoute: 'appliance_types'


### Appliance type ###
App.ApplianceTypeController = App.EditDeleteContentController.extend
  visibilities: ['unpublished', 'published']
  contentType: 'appliance_type'
  indexRoute: 'appliance_types'

