require_relative "client.rb"
require_relative "host_metric.rb"
require_relative "query_builder.rb"

module Zabbix
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

    def collect
      qb = QueryBuilder.new
      qb.add_params(:itemids => ids)
      qb.add_params(:limit => HostMetric::ITEM_LIMIT * metrics.size)
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

    def collect_last
      items = client.host_items(@host_id)
      items.each { |item| metrics[item["name"]].reload(item) if metrics.has_key?([item["name"]]) }
      metrics.values.map { |metric| { metric.name => metric.last_value } }
    end

    private

    def load_metrics
      @items = client.host_items(@host_id)
      @metrics = {}
      @items.each { |item| @metrics[item["name"]] = HostMetric.new(item, client) if (@metrics_names.include?(item["name"])) }
      @metrics
    end

    def client
      @client ||= Client.new
    end

  end
end
