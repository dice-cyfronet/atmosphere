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

          def owned_payload!(check_not_found=true)
            found_owned_payload = owned_payload(params[:name])
            if found_owned_payload
              found_owned_payload
            else
              not_found! if check_not_found
            end
          end

          def user_owned_payload!(check_not_found=true)
            proxy = owned_payload!(check_not_found)
            if proxy.blank? or proxy.users.include? current_user
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