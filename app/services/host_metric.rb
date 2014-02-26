class HostMetric < Metric

  attr_accessor :body, :id

  def initialize(client, body)
    super(client, body)
  end

  def collect
    @client.history(@id)
  end


end