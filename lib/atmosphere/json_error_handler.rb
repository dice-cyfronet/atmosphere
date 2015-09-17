module Atmosphere
  module JsonErrorHandler
    def render_json_error(msg, options = {})
      error_json = {
        message: msg,
        type: options[:type] || :general
      }
      error_json[:details] = options[:details] if options[:details]

      render(
        json: error_json,
        status: options[:status] || :bad_request
      )
    end
  end
end
