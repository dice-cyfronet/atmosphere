class Cloud::VmCreator
  def initialize(tmpl, options={})
    @tmpl = tmpl
    @flavor = options[:flavor] || tmpl.compute_site.default_flavor
    @name = options[:name] || tmpl.name
    @user_data = options[:user_data]
    @user_key = options[:user_key]
  end

  def spawn_vm!
    register_user_key!

    server_params = {
      flavor_ref: flavor_id, flavor_id: flavor_id,
      name: @name,
      image_ref: tmpl_id, image_id: tmpl_id
    }
    server_params[:user_data] = user_data if user_data
    server_params[:key_name] = key_name if key_name

    set_security_groups!(server_params)

    Rails.logger.debug "Params of instantiating server #{server_params}"
    server = servers_client.create(server_params)
    create_tags(server.id)

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
    @tmpl.compute_site.cloud_client
  end

  def set_security_groups!(params)
    params[:groups] = ['mniec_permit_all'] if amazon?
  end

  def register_user_key!
    @user_key.import_to_cloud(@tmpl.compute_site) if @user_key
  end

  def create_tags(server_id)
    begin
      VmTagsCreatorWorker.perform_async(server_id, @tmpl.compute_site.id, {'Name' => @name, 'Appliance type name' => @tmpl.appliance_type.name}) if amazon?
    rescue Fog::Compute::AWS::NotFound => e
      Raven.capture_exception(e)
    end
  end

  def amazon?
    @tmpl.compute_site.technology == 'aws'
  end
end