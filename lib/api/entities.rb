module API
  module Entities
    class OwnedPayload < Grape::Entity
      expose :name, :payload
      expose :owners do |proxy, options|
        proxy.users.collect do |user|
          user.login
        end
      end
    end

    class ApplianceSet < Grape::Entity
      expose :name, :priority, :id
      expose :type do |appliance_set, options|
        appliance_set.appliance_set_type
      end
    end
  end
end