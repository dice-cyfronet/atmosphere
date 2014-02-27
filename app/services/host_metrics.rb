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

  def collect_all
    # TODO batch collection
    metrics.values.map{ |metric| {metric.name => metric.collect} }
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