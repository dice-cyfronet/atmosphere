class Metric

  attr_accessor :body, :id, :name, :key, :type

  def initialize(body, client)
    @client = client
    init_structure(body)
  end

  def reload(new_body = nil)
    unless new_body
      new_body = client.item(@id)
      raise "Error reloading metric" if (new_body.nil? || new_body.size != 1)
    end
    init_structure(new_body.first)
    self
  end

  protected

  def client
    @client ||= ZabbixClient.new
  end

  def init_structure(body)
    @body = body
    @id = body["itemid"].to_i
    @type = body["type"].to_i
    @name = body["name"]
    @key = body["key_"]
    @last_value = body["lastvalue"]
  end

end