class Metric

  attr_accessor :body, :id, :name, :key, :type,

  def initialize(client, body)
    @client = client
    init_structure(body)
  end

  def read
    qb = QueryBuilder.new
    qb.add_params(:history => @type)
    result = @client.history(@id, qb)
    result.map{ |measure| MetricValueEvaluator.evaluate(@type, measure["value"])}
  end

  def reload_structure
    new_body = @client.item(@id)
    raise "Error reloading metric" if (new_body.nil? || new_body.size != 1)
    init_structure(new_body.first)
    self
  end

  private

  def init_structure(body)
    @body = body
    @id = body["itemid"].to_i
    @type = body["type"].to_i
    @name = body["name"]
    @key = body["key_"]
  end

end