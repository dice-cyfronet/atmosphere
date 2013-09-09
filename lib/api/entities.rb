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

    class ApplianceTypeLinks < Grape::Entity
      expose :user_id, as: :admin
      expose :security_proxy_id, as: :security_proxy
      expose :port_mapping_templates do |appliance_type, options|
        appliance_type.port_mapping_templates.map(&:id)
      end
      expose :appliance_configuration_templates do |appliance_type, options|
        appliance_type.appliance_configuration_templates.map(&:id)
      end
    end
  end
end