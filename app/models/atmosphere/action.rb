module Atmosphere
  class Action < ActiveRecord::Base
    belongs_to :appliance,
               class_name: 'Atmosphere::Appliance'

    has_many :action_logs, -> { order(id: :asc) },
             dependent: :destroy,
             class_name: 'Atmosphere::ActionLog'

    def log(message, level = :info)
      action_logs.create(message: message, log_level: level)
    end

    def warn(message)
      log(message, :warn)
    end

    def error(message)
      log(message, :error)
    end
  end
end
