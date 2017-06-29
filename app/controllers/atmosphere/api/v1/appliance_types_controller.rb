module Atmosphere
  module Api
    module V1
      class ApplianceTypesController < Atmosphere::Api::ApplicationController
        load_and_authorize_resource :appliance_type,
          except: :create,
          class: 'Atmosphere::ApplianceType'

        authorize_resource :appliance_type,
          only: :create,
          class: 'Atmosphere::ApplianceType'

        include Atmosphere::Api::Auditable

        respond_to :json

        def index
          process_active_query
          process_saving_query

          Rails.logger.debug("Requesting AT list from AT controller.")
          Rails.logger.debug("My PDP is #{pdp.class.inspect}.")

          ats = @appliance_types.where(filter).order(:id)
          respond_with pdp.new(current_user).filter(ats, params[:mode]).distinct,
                       each_serializer: Atmosphere::ApplianceTypeSerializer,
                       load_all?: load_all?
        end

        def show
          respond_with @appliance_type
        end

        def create
          appl = appliance_type_params['appliance_id'] &&
                 Appliance.find(appliance_type_params['appliance_id'])

          if appl
            authorize!(:save_vm_as_tmpl, appl)
            check_for_conflict!(appl)
          else
            raise ActionController::ParameterMissing,
                  I18n.t('appliance_types.appl_id_missing')
          end

          @appliance_type =
            Atmosphere::SaveAsService.new(current_user, appl,
                                          appliance_type_params).execute

          render json: @appliance_type, serializer: ApplianceTypeSerializer, status: :created
        end

        def update
          update_params = appliance_type_params
          appliance_id = update_params.delete 'appliance_id'
          author_id = update_params.delete(:author_id)
          update_params[:author] = Atmosphere::User.find(author_id) if author_id

          Atmosphere::ApplianceType.transaction do
            @appliance_type.update_attributes!(update_params)
            perform_save(appliance_id) if appliance_id
          end
          render json: @appliance_type, serializer: ApplianceTypeSerializer
        end

        def destroy
          if @appliance_type.destroy
            render json: {}
          else
            render_error @appliance_type
          end
        end

        def endpoint_payload
          render plain: Atmosphere::Endpoint.at_endpoint(
                                              @appliance_type,
                                              params[:service_name],
                                              params[:invocation_path]
                                            ).take!.descriptor
        end

        private

        def check_for_conflict!(appl)
          vm = appl.virtual_machines.first
          if vm && vm.state.saving?
            raise Atmosphere::Conflict,
                  I18n.t('appliance_types.conflict')
          end
        end

        def perform_save(appliance_id)
          appl = Atmosphere::Appliance.find(appliance_id)
          authorize!(:save_vm_as_tmpl, appl)

          Atmosphere::Cloud::SaveWorker.
            perform_async(appliance_id, @appliance_type.id)
        end

        def process_active_query
          active = params[:active]
          unless active.blank?
            @appliance_types =
              if to_boolean(active)
                @appliance_types.active
              else
                @appliance_types.inactive
              end
          end
        end

        def process_saving_query
          saving = params[:saving]
          unless saving.blank?
            @appliance_types =
              if to_boolean(saving)
                @appliance_types.saving
              else
                @appliance_types.not_saving
              end
          end
        end

        def filter
          filter = super
          author_id = params[:author_id]
          filter[:user_id] = author_id unless author_id.blank?
          filter
        end

        def appliance_type_params
          allowed_params = [
            :name, :description, :shared, :scalable,
            :visible_to, :author_id, :preference_cpu,
            :preference_memory, :preference_disk,
            :appliance_id
          ] + update_params_ext

          params.require(:appliance_type).permit(allowed_params)
        end

        # def pdp
        #   Atmosphere.at_pdp(current_user)
        # end

        def model_class
          Atmosphere::ApplianceType
        end

        include Atmosphere::Api::V1::ApplianceTypesControllerExt
      end
    end
  end
end