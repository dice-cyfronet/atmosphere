class Metric

  attr_accessor :body, :id

  def initialize(client, body)
    @client = client
    init_structure(body)
  end

  def reload
    new_body = @client.item(@id)
    raise "Error reloading metric" if (new_body.nil? || new_body.size != 1)
    init_structure(new_body.first)
    self
  end

  private

  def init_structure(body)
    @body = body
    @id = body["itemid"].to_i
    @type = MetricValueType.new(body["type"])
  end

end