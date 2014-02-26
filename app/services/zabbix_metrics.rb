class ZabbixMetrics

  def initialize(template_name = nil)
    @config = Air.config.zabbix
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
    raise "Method only applicable for Integer id" if !host_id.is_a? Integer
    host_items = client.host_items(host_id)
    host_metrics = {}
    host_items.each { |item| host_metrics[item["name"]] = HostMetric.new(client, item) if (metrics.has_key?(item["name"])) }
    host_metrics
  end

  private

  def init_metrics
    @items = client.template_items(@template_name)
    @metrics = {}
    @items.each { |item| @metrics[item["name"]] = Metric.new(client,item) }
    @metrics
  end

  def client
    @client ||= ZabbixClient.new
  end

end