require 'atmosphere/json_error_handler'
require 'rack'
require 'logger'
class HandleInvalidPercentEncoding
  include Atmosphere::JsonErrorHandler

  attr_reader :logger
  def initialize(app, stdout = STDOUT)
    @app = app
    @logger = defined?(Rails.logger) ? Rails.logger : Logger.new(stdout)
  end

  def call(env)
    # calling env.dup here prevents bad things from happening
    request = Rack::Request.new(env.dup)
    # calling request.params is sufficient to trigger the error
    # see https://github.com/rack/rack/issues/337#issuecomment-46453404
    request.params
    @app.call(env)
  rescue ArgumentError => e
    raise unless e.message =~ /invalid %-encoding/
    render_json_error('Wrong encoding',
                      status: :bad_request,
                      type: :bad_request)
  end
end
