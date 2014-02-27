class ZabbixMetrics

  def initialize(template_name = nil, client = nil)
    @config = Air.config.zabbix
    @client = client
    @template_name = template_name || @config.template_name
  end

  def metrics
    @metrics || init_metrics
  end

  def reload
    init_metrics
    metrics.keys
  end

  def create_host_metrics(host_id)
    HostMetrics.new(host_id, metrics.keys, client)
  end

  private

  def init_metrics
    @items = client.template_items(@template_name)
    @metrics = {}
    @items.each { |item| @metrics[item["name"]] = Metric.new(item, client) }
    @metrics
  end

  def client
    @client ||= ZabbixClient.new
  end

end