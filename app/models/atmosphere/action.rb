module Atmosphere
  class Action < ActiveRecord::Base

    belongs_to :appliance,
               class_name: 'Atmosphere::Appliance'

    has_many :action_logs,
             dependent: :destroy,
             class_name: 'Atmosphere::ActionLog'


  end
end
