module Air
  Revision = `git log --pretty=format:'%h' -n 1`

  def self.config
    Settings
  end

  @@cloud_clients = {}

  def self.register_cloud_client(site_id, cloud_client)
    @@cloud_clients[site_id] = {timestamp: Time.now, client: cloud_client}
  end

  def self.unregister_cloud_client(site_id)
    @@cloud_clients.delete(site_id)
  end

  def self.get_cloud_client(site_id)
    (@@cloud_clients[site_id] and (Time.now - @@cloud_clients[site_id][:timestamp]) < 23.hours) ? @@cloud_clients[site_id][:client] : nil
  end

  def self.action_logger
    @@action_logger ||= Logger.new(Rails.root.join('log', 'user_actions.log'))
  end

  def self.monitoring_logger
    @@monitoring_logger ||= Logger.new(Rails.root.join('log', 'monitoring.log'))
  end
end