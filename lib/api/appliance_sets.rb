module API
  class ApplianceSets < Grape::API
    before { authenticate! }

    helpers do
      def appliance_sets
        current_user.appliance_sets if can? :index, ApplianceSet
      end

      def appliance_set
        @appliance_set ||= ApplianceSet.find(params[:id])
      end

      def appliance_set!(action)
        not_found! ApplianceSet unless appliance_set
        render_api_error! I18n.t('api.e403', action: action, type: 'appliance set'), 403 unless can? action, appliance_set
        appliance_set
      end
    end

    resource :appliance_sets do
      get do
        present appliance_sets, with: Entities::ApplianceSet
      end

      post do
        attrs = attributes_for_keys [:name, :priority]
        attrs[:appliance_set_type] = params[:type] if params[:type]

        new_set = ApplianceSet.new attrs
        new_set.user = current_user
        if can? :create, new_set
          if new_set.save
            present new_set, with: Entities::ApplianceSet
          else
            entity_errors!(new_set)
          end
        else
          render_api_error! 'You are not allowed to create this type of appliance set', 403
        end
      end

      get ':id' do
        present appliance_set!(:show), with: Entities::ApplianceSet
      end

      put ':id' do
        attrs = attributes_for_keys [:name, :priority]
        if appliance_set!(:update).update(attrs)
          present appliance_set!(:show), with: Entities::ApplianceSet
        else
          entity_errors!(new_set)
        end
      end

      delete ':id' do
        appliance_set!(:destroy).destroy
      end
    end
  end
end