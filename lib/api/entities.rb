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
  end
end