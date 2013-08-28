module API
  class ApplianceTypes < Grape::API
    before { authenticate! }

    helpers do
      def appliance_types
        ApplianceType.all if can? :index, ApplianceType
      end

      def appliance_type
        @appliance_set ||= ApplianceType.where(id: params[:id]).first
      end

      def appliance_type!(action, check_not_found=true)
        if appliance_type
          render_api_error! I18n.t('api.e403', action: action, type: 'appliance type'), 403 unless can? action, appliance_type
          appliance_type
        else
          not_found! ApplianceSet if check_not_found
        end
      end

      def security_proxy!
        security_proxy = SecurityProxy.find_by(name: params[:security_proxy])
        not_found! SecurityProxy unless security_proxy
        security_proxy
      end
    end

    resource :appliance_types do
      get do
        present appliance_types, with: Entities::ApplianceType
      end

      get ':id' do
        present [appliance_type!(:show)], with: Entities::ApplianceType
      end

      put ':id' do
        attrs = attributes_for_keys [:name, :description, :shared, :scalable, :visibility, :preference_cpu, :preference_memory, :preference_disk]
        attrs[:security_proxy] = security_proxy! if params[:security_proxy]

        if appliance_type!(:update).update(attrs)
          present [appliance_type!(:show)], with: Entities::ApplianceType
        else
          entity_errors!(appliance_type)
        end
      end

      delete ':id' do
        appliance_type = appliance_type!(:destroy, false)
        appliance_type.destroy if appliance_type
      end
    end
  end
end