### Users ###
App.UsersController = App.FilteredContentController.extend
  sortProperties: ['full_name']
  sortAscending: false


### User ###
App.UserController = App.EditDeleteContentController.extend
  contentType: 'user'
  indexRoute: 'users'