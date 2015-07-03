module Atmosphere
  class Cloud::VmCreator

    prepend Atmosphere::Cloud::VmCreatorExt

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

      # TODO: Change to ComputeSite.technology once ComputeSite is reinstated.
      case (@tenant.technology)
      when 'azure'
        server_params[:vm_name] = SecureRandom.hex(5)
        server_params[:vm_user] = Atmosphere.azure_vm_user
        server_params[:password] = Atmosphere.azure_vm_password
        server_params[:image] = tmpl_id
        server_params[:location] = 'North Europe'
        server_params[:cs_id] = @tenant.site_id
        server_params[:vm_size] = flavor_id
        set_azure_endpoints(server_params)
      else # TODO: Untangle AWS and OpenStack
        server_params[:atmo_user_key] = @user_key
        server_params[:flavor_ref] = flavor_id
        server_params[:flavor_id] = flavor_id
        server_params[:name] = @name
        server_params[:image_ref] = tmpl_id
        server_params[:image_id] = tmpl_id
        server_params[:user_data] = user_data if user_data
        server_params[:key_name] = key_name if key_name
        set_security_groups!(server_params)
      end

      Rails.logger.debug "Params of instantiating server #{server_params}"
      server = servers_client.create(server_params)

      server.id
    end

    private

    attr_reader :user_data

    def set_azure_endpoints(params)
      tcp_endpoints_str = ''
      udp_endpoints_str = ''
      @appliance_type.port_mapping_templates.
        each do |pmt|
          if pmt.transport_protocol == :tcp
            # 22 ssh is present by default on Azure for linux
            # and if it is specified explicitly it causes error
            unless pmt.target_port == 22 
              tcp_endpoints_str << "#{pmt.target_port}:#{pmt.target_port},"
            end
          else
            udp_endpoints_str << "#{pmt.target_port}:#{pmt.target_port},"
          end
        end
      if tcp_endpoints_str.present?
        params[:tcp_endpoints] = tcp_endpoints_str.chomp!(',')
      end
      if udp_endpoints_str.present?
        params[:udp_endpoints] = udp_endpoints_str.chomp!(',')
      end
    end

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
      params[:network] = 'permitall' if google?
    end

    def register_user_key!
      @user_key.import_to_cloud(@tenant) if @user_key
    end

    def amazon?
      @tenant.technology == 'aws'
    end

    def google?
      @tenant.technology == 'google_compute'
    end
  end
end
