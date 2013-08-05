module API
  module APIHelpers
    def current_user
      @current_user ||= User.find_by_authentication_token(params[:private_token] || env["HTTP_PRIVATE_TOKEN"])
    end

    def authenticate!
      unauthorized! unless current_user
    end

    def unauthorized!
      render_api_error!('401 Unauthorized', 401)
    end

    def render_api_error!(message, status)
      error!({'message' => message}, status)
    end
  end
end