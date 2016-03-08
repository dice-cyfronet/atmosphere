module Atmosphere
  class Cloud::VmCreator

    include Atmosphere::Cloud::VmCreatorExt

    def initialize(tmpl, options={})
      @tmpl = tmpl
      @tenant = options[:tenant] || tmpl.tenants.first
      @flavor = options[:flavor] || @tenant.default_flavor
      @name = options[:name] || tmpl.name
      @user_data = options[:user_data]
      @user_key = options[:user_key]
      @nic = options[:nic]
      @appliance_type = @tmpl.appliance_type
    end

    def execute
      register_user_key!
      server_params = {}
      server_params[:user_data] = user_data if user_data
      server_params[:key_name] = key_name if key_name
      if @nic
        Rails.logger.info "Spawning server with forced NIC: #{@nic}"
        server_params[:nics] = [{ net_id: @nic }]
      end

      server_params[:atmo_user_key] = @user_key
      server_params[:flavor_ref] = flavor_id
      server_params[:flavor_id] = flavor_id
      server_params[:name] = @name
      server_params[:image_ref] = tmpl_id
      server_params[:image_id] = tmpl_id
      server_params[:user_data] = user_data if user_data
      server_params[:key_name] = key_name if key_name
      set_security_groups!(server_params)

      Rails.logger.debug "Params of instantiating server #{server_params}"
      server = servers_client.create(server_params)

      server.id
    end

    private

    attr_reader :user_data

    def flavor_id
      @flavor.id_at_site
    end

    def tmpl_id
      @tmpl.id_at_site
    end

    def servers_client
      client.servers
    end

    def key_name
      @user_key.id_at_site if @user_key
    end

    def client
      @tenant.cloud_client
    end

    def set_security_groups!(params)
      params[:groups] = ['mniec_permit_all'] if amazon?
    end

    def register_user_key!
      @user_key.import_to_cloud(@tenant) if @user_key
    end

    def amazon?
      @tenant.technology == 'aws'
    end
  end
end
