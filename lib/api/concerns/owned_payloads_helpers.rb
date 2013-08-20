module API
  module Concerns
    module OwnedPayloadsHelpers
      extend ActiveSupport::Concern

      included do
        helpers do
          def owners
            if params[:owners]
              User.where(login: params[:owners])
            else
              [current_user]
            end
          end

          def owned_payload!
            not_found! unless owned_payload(params[:name])
            owned_payload(params[:name])
          end

          def user_owned_payload!
            proxy = owned_payload!
            if proxy.users.include? current_user
              proxy
            else
              render_api_error!('You are not an owner of this policy', 403)
            end
          end
        end
      end
    end
  end
end