module TsdbClient

  def client
    Client.new(Air.config.influxdb.host, Air.config.influxdb.database, Air.config.influxdb.username, Air.config.influxdb.password)
  end

  class Client

    def initialize(host, database, username, password)
      @influxdb = InfluxDB::Client.new(database, {host: host,username: username, password: password})
    end

    def write_point(series_name, point_data)
      @influxdb.write_point(series_name, point_data)
    end

  end

  module_function :client

end