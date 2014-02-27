class HostMetric < Metric

  attr_accessor :body, :id, :results

  def initialize(body, client)
    super(body, client)
  end

  def collect
    qb = QueryBuilder.new
    qb.add_params(:itemids => @id)
    qb.add_params(:history => @type)
    store_results(client.history(qb))
  end

  def store_results(results)
    @results = results
    evaluated_results
  end

  def evaluated_results
    @results.map{ |measure| MetricValueEvaluator.evaluate(@type, measure["value"])}
  end

end