module API
  class ApplianceSets < Grape::API
    before { authenticate! }

    helpers do
      def appliance_sets
        current_user.appliance_sets
      end

      def appliance_set
        @appliance_set ||= appliance_sets.find(params[:id])
      end

      def appliance_set!
        not_found! ApplianceSet unless appliance_set
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
        if new_set.save
          present new_set, with: Entities::ApplianceSet
        else
          bad_request!(:appliance_set_type, new_set.errors[:appliance_set_type].first) if new_set.errors[:appliance_set_type]
        end
      end

      get ':id' do
        present appliance_set, with: Entities::ApplianceSet
      end
    end
  end
end