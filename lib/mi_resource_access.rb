class MiResourceAccess

  def initialize(type, options={})
    @type = type
    @connection = options[:connection] || initialize_connection(options)
  end

  def has_role?(local_id, role)
    response = @connection.get '/api/hasrole/',
      {local_id: local_id, type: @type, role: role}

    response.status == 200 && response.body == 'True'
  end

  def avaialbe_resource_ids(role)
    response = @connection.get '/api/resources',
      {type: @type, role: role}

    response.status == 200 ? resource_ids(response.body) : []
  end

  private

  def resource_ids(response_body)
    JSON.parse(response_body).collect { |el| el['local_id'] }
  end

  def initialize_connection(options)
    mi_url = options[:mi_uri] || Air.config.vph.host
    mi_ticket = options[:mi_ticket]
    verify = options[:verify]

    Faraday.new(url: mi_url, :ssl => {:verify => verify}) do |faraday|
      faraday.request :url_encoded
      faraday.response :logger
      faraday.adapter Faraday.default_adapter
      faraday.basic_auth('', mi_ticket)
    end
  end
end