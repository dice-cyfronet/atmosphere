module Air
  Revision = `git log --pretty=format:'%h' -n 1`

  def self.config
    Settings
  end

  @@cloud_clients = {}

  def self.cloud_clients
    @@cloud_clients
  end

  def self.action_logger
    @@action_logger ||= Logger.new(Rails.root.join('log', 'user_actions.log'))
  end
end