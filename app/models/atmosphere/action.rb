module Atmosphere
  class Action < ActiveRecord::Base
    belongs_to :appliance,
               class_name: 'Atmosphere::Appliance'

    has_many :action_logs, -> { order(id: :asc) },
             dependent: :destroy,
             class_name: 'Atmosphere::ActionLog'

    def log(message, level = :info)
      action_logs.create(message: message, log_level: level)
      logger.send(level, "#{prefix} #{message}")
    end

    def warn(message)
      log(message, :warn)
    end

    def error(message)
      log(message, :error)
    end

    def logger=(logger)
      @logger = logger
    end

    private

    def logger
      @logger || Rails.logger
    end

    def prefix
      @prefix ||= "[appliance #{appliance.id}] "
    end
  end
end
