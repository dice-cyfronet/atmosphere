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
          owned_payload!.payload
        end

        get ':name', requirements: { name: /#{OwnedPayloable.name_regex}\z/ } do
          present owned_payload!, with: Entities::OwnedPayload
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
            bad_request!(:name, new_owned_payload.errors[:name].first) if new_owned_payload.errors[:name]
            bad_request!(:payload, new_owned_payload.errors[:payload].first) if new_owned_payload.errors[:payload]
          end
        end

        put ':name', requirements: { name: /#{OwnedPayloable.name_regex}\z/ } do
          authenticate!
          user_owned_payload!.payload = params[:payload] if params[:payload]
          user_owned_payload!.users = owners if params[:owners]

          present user_owned_payload!, with: Entities::OwnedPayload
        end

        delete ':name', requirements: { name: /#{OwnedPayloable.name_regex}\z/ } do
          authenticate!
          user_owned_payload!.destroy
        end
      end
    end
  end
end