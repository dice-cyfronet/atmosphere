class HostMetric < Metric

  attr_accessor :body, :id

  def initialize(body, client)
    super(body, client)
  end

  def collect
    qb = QueryBuilder.new
    qb.add_params(:history => @type)
    result = client.history(@id, qb)
    @last_results = result
    result.map{ |measure| MetricValueEvaluator.evaluate(@type, measure["value"])}
  end

end