class HostMetrics

  def initialize(host_id, metrics_names, client = nil)
    @client = client
    @host_id = host_id
    @metrics_names = metrics_names
  end

  def metrics
    @metrics || load_metrics
  end

  def reload
    load_metrics
    metrics.keys
  end

  def ids
    metrics.values.map{ |metric| metric.id }
  end

  def collect_all
    client.history

    qb = QueryBuilder.new
    qb.add_params(:itemids => ids)
    results = client.history(qb)

    sorted = {}

    results.each do |res|
      id = res["itemid"].to_i
      if sorted.has_key?(id)
        sorted[id] += [res]
      else
        sorted[id] = [res]
      end
    end

    metrics.values.map do |metric|
      metric.store_results(sorted.has_key?(metric.id) ? sorted[metric.id] : [])
      { metric.name => metric.evaluated_results }
    end

  end

  private

  def load_metrics
    @items = client.host_items(@host_id)
    @metrics = {}
    @items.each { |item| @metrics[item["name"]] = HostMetric.new(item, client) if (@metrics_names.include?(item["name"])) }
    @metrics
  end

  def client
    @client ||= ZabbixClient.new
  end

end