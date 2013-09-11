### Security Proxies ###
App.SecurityProxiesController = App.FilteredContentController.extend
  sortProperties: ['name']
  sortAscending: true

App.SecurityProxiesNewController = App.NewContentController.extend
  contentType: 'security_proxy'
  indexRoute: 'security_proxies'

### Security Proxy ###
App.SecurityProxyController = App.EditDeleteContentController.extend
  contentType: 'security_proxy'
  indexRoute: 'security_proxies'