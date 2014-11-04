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

        respond_to :json

        def index
          process_active_query
          ats = @appliance_types.where(filter).order(:id)
          respond_with pdp.filter(ats, params[:mode])
        end

        def show
          respond_with @appliance_type
        end

        def create
          log_user_action "create new appliance type with following params #{params}"
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
          log_user_action "appliance type created: #{@appliance_type.to_json}"
        end

        def update
          log_user_action "update appliance type #{@appliance_type.id} with following params #{params}"
          update_params = appliance_type_params
          update_params.delete 'appliance_id'
          author_id = update_params.delete(:author_id)
          update_params[:author] = Atmosphere::User.find(author_id) if author_id

          @appliance_type.update_attributes!(update_params)
          render json: @appliance_type, serializer: ApplianceTypeSerializer
          log_user_action "appliance type updated: #{@appliance_type.to_json}"
        end

        def destroy
          log_user_action "destroy appliance type #{@appliance_type.id}"
          if @appliance_type.destroy
            render json: {}
            log_user_action "appliance type #{@appliance_type.id} destroyed"
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

        def process_active_query
          active = params[:active]
          unless active.blank?
            @appliance_types = to_boolean(active) ? @appliance_types.active : @appliance_types.inactive
          end
        end

        def filter
          filter = super
          author_id = params[:author_id]
          filter[:user_id] = author_id unless author_id.blank?

          filter
        end

        def appliance_type_params
          params.require(:appliance_type).permit(:name, :description, :shared, :scalable, :visible_to, :author_id, :preference_cpu, :preference_memory, :preference_disk, :appliance_id)
        end

        def pdp
          Atmosphere.at_pdp(current_user)
        end

        def model_class
          Atmosphere::ApplianceType
        end
      end
    end
  end
end