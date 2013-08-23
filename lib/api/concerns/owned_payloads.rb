module API
  module Concerns
    module OwnedPayloads
      extend ActiveSupport::Concern

      included do
        get do
          present all, with: Entities::OwnedPayload
        end

        get ':name/payload', requirements: { name: /#{OwnedPayloable.name_regex}/ } do
          env['api.format'] = :text
          content_type "text/plain"
          owned_payload!(:show).payload
        end

        get ':name', requirements: { name: /#{OwnedPayloable.name_regex}\z/ } do
          present owned_payload!(:show), with: Entities::OwnedPayload
        end

        post do
          authenticate!
          required_attributes! [:name, :payload]
          attrs = attributes_for_keys [:name, :payload]

          new_owned_payload = new_owned_payload attrs
          new_owned_payload.users << owners
          if new_owned_payload.save
            present new_owned_payload, with: Entities::OwnedPayload
          else
            entity_error! new_owned_payload
          end
        end

        put ':name', requirements: { name: /#{OwnedPayloable.name_regex}\z/ } do
          authenticate!
          owned_payload = owned_payload!(:update)
          owned_payload.payload = params[:payload] if params[:payload]
          owned_payload.users = owners if params[:owners]

          if owned_payload.save
            present owned_payload!(:show), with: Entities::OwnedPayload
          else
            entity_error! new_owned_payload
          end
        end

        delete ':name', requirements: { name: /#{OwnedPayloable.name_regex}\z/ } do
          authenticate!
          owned_payload = owned_payload!(:destroy, false)
          owned_payload.destroy if owned_payload
        end
      end
    end
  end
end