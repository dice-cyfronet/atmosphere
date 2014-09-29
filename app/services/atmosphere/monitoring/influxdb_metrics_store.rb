module Atmosphere
  module Monitoring
    class InfluxdbMetricsStore
      def initialize(conf)
        @influxdb_client = InfluxDB::Client.new(conf['database'], {host: conf['host'],username: conf['username'], password: conf['password']})
      end

      def write_point(series_name, point_data)
        @influxdb_client.write_point(series_name, point_data)
      end
    end
  end
end
