class WranglerRegistrarWorker
  include Sidekiq::Worker

  sidekiq_options queue: :wrangler

  def perform

  end

  # conn = Faraday.new(url: 'http://10.100.0.24:8400') do |faraday|
  #   faraday.request :url_encoded
  #   faraday.response :logger 
  #   faraday.adapter Faraday.default_adapter
  #   faraday.basic_auth(user,passwd)
  # end
  # conn,get '/dnat'

end