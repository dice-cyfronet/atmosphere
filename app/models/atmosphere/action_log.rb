module Atmosphere
  class ActionLog < ActiveRecord::Base
    extend Enumerize

    belongs_to :action,
               class_name: 'Atmosphere::Action'

    enumerize :log_level, in: [:info, :warn, :error], default: :info
  end
end
