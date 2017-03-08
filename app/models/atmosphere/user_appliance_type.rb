# Linking table for Users and ApplianceTypes (local PDP)
module Atmosphere
  class UserApplianceType < ActiveRecord::Base
    belongs_to :user,
               class_name: 'Atmosphere::User'

    belongs_to :appliance_type,
               class_name: 'Atmosphere::ApplianceType'

    validates :user_id,
              uniqueness: {
                scope: :appliance_type_id,
              }

    validates :role,
              inclusion: %w(reader developer manager)
  end
end
