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

          ats = @appliance_types.where(filter).order(:id)
          respond_with pdp.filter(ats, params[:mode])
        end

        def show
          respond_with @appliance_type
        end

        def create
          appl = Appliance.find appliance_type_params['appliance_id'] if appliance_type_params['appliance_id']
          tmpl = nil
          vm = nil
          if appl
            authorize!(:save_vm_as_tmpl, appl)
            vm = appl.virtual_machines.first
            raise Atmosphere::Conflict.new("It is not allowed to save application twice") if vm && vm.state.saving?
          else
            unless current_user.admin?
              raise ActionController::ParameterMissing.new('appliance_id parameter is missing')
            end
          end
          begin
            Atmosphere::ApplianceType.transaction do
              tmpl = Atmosphere::VirtualMachineTemplate.create_from_vm(vm, appliance_type_params[:name]) if vm

              new_at_params = appliance_type_params.dup
              new_at_params['user_id'] = new_at_params.delete('author_id')

              @appliance_type = Atmosphere::ApplianceType.create_from(appl, new_at_params)
              @appliance_type.virtual_machine_templates << tmpl if tmpl
              @appliance_type.author = current_user if @appliance_type.author.blank?

              @appliance_type.save!
            end
          rescue
            if tmpl and tmpl.id_at_site
              tmpl.perform_delete_in_cloud
            end
            raise $!
          end

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
          render text: Atmosphere::Endpoint.at_endpoint(
                                              @appliance_type,
                                              params[:service_name],
                                              params[:invocation_path]
                                            ).take!.descriptor
        end

        private

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

        def pdp
          Atmosphere.at_pdp(current_user)
        end

        def model_class
          Atmosphere::ApplianceType
        end

        include Atmosphere::Api::V1::ApplianceTypesControllerExt
      end
    end
  end
end