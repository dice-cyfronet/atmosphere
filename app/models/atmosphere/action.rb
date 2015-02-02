module Atmosphere
  class Action < ActiveRecord::Base

    belongs_to :appliance,
               class_name: 'Atmosphere::Appliance'

    has_many :action_logs,
             dependent: :destroy,
             class_name: 'Atmosphere::ActionLog'

    def log(message, level = :info)
      ActionLog.create(action: self, log_level: level)
    end

    def warn(message)
      log(message, :warn)
    end

    def error(message)
      log(message, :error)
    end

  end
end
