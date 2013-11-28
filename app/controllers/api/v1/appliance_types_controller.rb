module Api
  module V1
    class ApplianceTypesController < Api::ApplicationController
      load_and_authorize_resource :appliance_type, except: :create
      authorize_resource :appliance_type, only: :create
      respond_to :json

      def index
        respond_with @appliance_types.where(filter).order(:id)
      end

      def show
        respond_with @appliance_type
      end

      def create
        log_user_action 'create new appliance type'
        appl = Appliance.find appliance_type_params['appliance_id'] if appliance_type_params['appliance_id']
        new_at_params = {}
        tmpl = nil
        if appl
          #if ((appl.appliance_set.user_id != current_user.id or appl.appliance_set.appliance_set_type != 'development') and not current_user.admin?)
          #  raise CanCan::AccessDenied
          #end
          authorize!(:save_vm_as_tmpl, appl)
          if appl.dev_mode_property_set
            new_at_params = appl.dev_mode_property_set.attributes
            new_at_params.delete('id')
            new_at_params.delete('created_at')
            new_at_params.delete('updated_at')
          end
          vm = appl.virtual_machines.first
          tmpl = VirtualMachineTemplate.create_from_vm(vm) if vm
        else
          unless current_user.admin?
            raise ActionController::ParameterMissing.new('appliance_id parameter is missing')#ActionController::ParameterMissing
          end
        end
        new_at_params.merge!(appliance_type_params)
        new_at_params.delete('appliance_id')
        @appliance_type = ApplianceType.new(new_at_params)
        @appliance_type.virtual_machine_templates << tmpl if tmpl
        @appliance_type.author = current_user if @appliance_type.author.blank?
        @appliance_type.save!
        render json: @appliance_type, serializer: ApplianceTypeSerializer, status: :created
        log_user_action "appliance type created: #{@appliance_type.to_json}"
      end

      def update
        log_user_action "update appliance type #{@appliance_type.id}"
        update_params = appliance_type_params
        update_params.delete 'appliance_id'
        author_id = update_params.delete(:author_id)
        update_params[:author] = User.find(author_id) if author_id

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
        render text: Endpoint.at_endpoint(@appliance_type, params[:service_name], params[:invocation_path]).take!.descriptor
      end

      private

      def appliance_type_params
        params.require(:appliance_type).permit(:name, :description, :shared, :scalable, :visible_for, :author_id, :preference_cpu, :preference_memory, :preference_disk, :security_proxy_id, :appliance_id)
      end
    end
  end
end