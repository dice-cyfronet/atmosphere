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

          def all
            render_api_error! I18n.t('api.e403', action: 'list', type: 'resource'), 403 unless can? :index, owned_payload_class

            owned_payload_class.all
          end

          def owned_payload(name)
            @owned_payload ||= owned_payload_class.where(name: name).first
          end

          def new_owned_payload(attrs)
            render_api_error! I18n.t('api.e403', action: 'create', type: 'resource'), 403 unless can? :new, owned_payload_class

            owned_payload_class.new attrs
          end

          def owned_payload!(action, check_not_found=true)
            found_owned_payload = owned_payload(params[:name])
            if found_owned_payload
              render_api_error! I18n.t('api.e403', action: action, type: 'resource'), 403 unless can? action, found_owned_payload
              found_owned_payload
            else
              not_found! if check_not_found
            end
          end
        end
      end
    end
  end
end