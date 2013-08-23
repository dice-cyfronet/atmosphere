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

    class ApplianceType < Grape::Entity
      expose :id, :name, :description, :shared, :scalable, :visibility
      expose :preference_cpu, :preference_memory, :preference_disk
      expose :author do |appliance_type, options|
        appliance_type.author.login if appliance_type.author
      end
      expose :security_proxy do |appliance_type, options|
        appliance_type.security_proxy.name if appliance_type.security_proxy
      end
    end
  end
end