module API
  module APIHelpers

    def can?(action, resource)
      ability.can? action, resource
    end

    def ability
      @aiblity = Ability.new(current_user)
    end

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
      error!({message: message}, status)
    end

    def not_found!(resource = nil)
      message = ["404"]
      message << resource if resource
      message << "Not Found"
      render_api_error!(message.join(' '), 404)
    end

    def required_attributes!(keys)
      keys.each do |key|
        bad_request!(key) unless params[key].present?
      end
    end

    def bad_request!(attribute, msg_postfix = nil)
      msg_postfix = "not given" if msg_postfix.blank?
      message = ["400 (Bad request)"]
      message << "\"" + attribute.to_s + "\" " + msg_postfix
      render_api_error!(message.join(' '), 400)
    end

    def attributes_for_keys(keys)
      attrs = {}
      keys.each do |key|
        attrs[key] = params[key] if params[key].present?
      end
      attrs
    end
  end
end