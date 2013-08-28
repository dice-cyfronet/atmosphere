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

    class ApplianceType < Grape::Entity
      root 'appliance_types', 'appliance_types'

      expose :id, :name, :description, :shared, :scalable, :visibility
      expose :preference_cpu, :preference_memory, :preference_disk

      #links
      expose :links do |at, options|
        {
          author: at.user_id,
          security_proxy: at.security_proxy_id,
          port_mapping_templates: at.port_mapping_templates.map(&:id),
          appliance_configuration_templates: at.appliance_configuration_templates.map(&:id)
          # XXX :appliances, :virtual_machine_templates for admin?
        }
      end
    end
  end
end