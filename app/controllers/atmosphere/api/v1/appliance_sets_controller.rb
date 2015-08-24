module Atmosphere
  module Api
    module V1
      class ApplianceSetsController < Atmosphere::Api::ApplicationController
        load_and_authorize_resource :appliance_set,
                                    class: 'Atmosphere::ApplianceSet'

        include Atmosphere::Api::Auditable

        respond_to :json

        before_filter :create_appliance_set, only: :create

        def index
          respond_with @appliance_sets.where(filter).order(:id)
        end

        def show
          respond_with @appliance_set
        end

        def create
          if !@appliance_set.appliance_set_type
            render_json_error(
                "Unable to create appliance set with type #{appliance_set_params[:appliance_set_type]}",
                status: :unprocessable_entity,
                type: :record_invalid
            )
          elsif conflicted? @appliance_set.appliance_set_type
            msg = "Unable to create two #{@appliance_set.appliance_set_type} appliance sets"
            render_json_error(msg, status: :conflict)
            log_user_action msg
          else
            @appliance_set.save!
            create_appliances if @appliances_params
            render json: @appliance_set,
                   serializer: ApplianceSetSerializer,
                   status: :created
          end
        end

        def update
          @appliance_set.update_attributes!(appliance_set_update_params)
          render json: @appliance_set,
                 serializer: ApplianceSetSerializer
        end

        def destroy
          if Atmosphere::DestroyApplianceSet.new(@appliance_set).execute
            render json: {}
          else
            render_error @appliance_set
          end
        end

        private

        def appliance_set_params
          if params[:appliance_set] && params[:appliance_set][:appliances]
            @appliances_params = params[:appliance_set][:appliances]
          end

          allowed_params = [
            :appliance_set_type,
            :name,
            :priority,
            :optimization_policy
          ] + create_params_ext

          params.require(:appliance_set).
            permit(allowed_params)
        end

        def appliance_set_update_params
          params.require(:appliance_set).permit(:name, :priority)
        end

        def create_appliance_set
          @appliance_set = ApplianceSet.new(appliance_set_params)
          @appliance_set.user = current_user
        end

        def create_appliances
          @appliances_params.each do |appl_params|
            appl_params[:appliance_set_id] = @appliance_set.id
            creator = ApplianceCreator.new(appl_params, delegate_auth)
            appl = creator.build
            Atmosphere::CreateApplianceService.new(appl).execute
            @appliance_set.appliances << appl
          end
        end

        def conflicted?(type)
          !type.workflow? && as_with_type(type).count > 0
        end

        def as_with_type(type)
          current_user.appliance_sets.where(appliance_set_type: type)
        end

        def set_appliance_sets
          return unless current_user
          @appliance_sets = if load_all?
                              ApplianceSet.all
                            else
                              current_user.appliance_sets
                            end
        end

        def model_class
          Atmosphere::ApplianceSet
        end

        include Atmosphere::Api::V1::ApplianceSetsControllerExt
      end
    end
  end
end
