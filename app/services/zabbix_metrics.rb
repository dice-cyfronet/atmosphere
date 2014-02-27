class ZabbixMetrics

  def initialize(client = nil, template_name = nil)
    @template_name = template_name || Air.config.zabbix.template_name
    @client = client
  end

  def metrics
    @metrics || load_metrics
  end

  def reload
    load_metrics
    metrics.keys
  end

  def create_host_metrics(host_id)
    HostMetrics.new(host_id, metrics.keys, client)
  end

  private

  def load_metrics
    @items = client.template_items(@template_name)
    @metrics = {}
    @items.each { |item| @metrics[item["name"]] = Metric.new(item, client) }
    @metrics
  end

  def client
    @client ||= ZabbixClient.new
  end

end