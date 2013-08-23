module API
  class ApplianceTypes < Grape::API
    before { authenticate! }

    helpers do
      def appliance_types
        ApplianceType.all
      end
    end

    resource :appliance_types do
      get do
        present appliance_types, with: Entities::ApplianceType
      end
    end
  end
end