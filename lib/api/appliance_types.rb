module API
  class ApplianceTypes < Grape::API
    before { authenticate! }

    helpers do
      def appliance_types
        ApplianceType.all if can? :index, ApplianceType
      end

      def appliance_type
        @appliance_set ||= ApplianceType.find(params[:id])
      end

      def appliance_type!(action)
        not_found! ApplianceSet unless appliance_type
        render_api_error! I18n.t('api.e403', action: action, type: 'appliance type'), 403 unless can? action, appliance_type
        appliance_type
      end
    end

    resource :appliance_types do
      get do
        present appliance_types, with: Entities::ApplianceType
      end

      get ':id' do
        present appliance_type!(:show), with: Entities::ApplianceType
      end
    end
  end
end