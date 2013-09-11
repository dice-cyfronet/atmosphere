### Security Policies ###
App.SecurityPoliciesController = App.FilteredContentController.extend
  sortProperties: ['name']
  sortAscending: true

App.SecurityPoliciesNewController = App.NewContentController.extend
  contentType: 'security_policy'
  indexRoute: 'security_policies'

### Security Policy ###
App.SecurityPolicyController = App.EditDeleteContentController.extend
  contentType: 'security_policy'
  indexRoute: 'security_policies'