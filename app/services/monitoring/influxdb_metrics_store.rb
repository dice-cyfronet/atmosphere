module Monitoring

  class InfluxdbMetricsStore

    def initialize(conf)
      @influxdb_client = InfluxDB::Client.new(conf.influxdb.database, {host: conf.influxdb.host,username: conf.influxdb.username, password: conf.influxdb.password})
    end

    def write_point(series_name, point_data)
      @influxdb_client.write_point(series_name, point_data)
    end

  end

end