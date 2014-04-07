#
# Taken from GitLab project
#
module ApiHelpers
  # Public: Prepend a request path with the path to the API
  #
  # path - Path to append
  # user - User object - If provided, automatically appends private_token query
  #          string for authenticated requests
  #
  # Examples
  #
  #   >> api('/appliances')
  #   => "/api/v2/appliances"
  #
  #   >> api('/appliances', User.last)
  #   => "/api/v2/appliances?private_token=..."
  #
  #   >> api('/appliances?foo=bar', User.last)
  #   => "/api/v2/appliances?foo=bar&private_token=..."
  #
  # Returns the relative path to the requested API resource
  def api(path, user = nil)
    "/api/v1/#{path}" +

      # Normalize query string
      (path.index('?') ? '' : '?') +

      # Append private_token if given a User object
      (user.respond_to?(:authentication_token) ?
        "&private_token=#{user.authentication_token}" : "")
  end

  def json_response
    JSON.parse(response.body)
  end
end