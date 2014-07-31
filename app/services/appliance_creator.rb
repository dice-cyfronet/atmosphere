class ApplianceCreator

  attr_reader :appliance

  def initialize(params, mi_authentication_key)
    @params = params
    @appliance = Appliance.new(create_params)
    @mi_authentication_key = mi_authentication_key
  end

  def create!
    check_for_at_instantiation_possibility!

    appliance.transaction do
      apply_preferences
      init_appliance_configuration
      init_billing

      appliance.save!
    end

    appliance
  end

  private

  attr_reader :params, :mi_authentication_key

  def create_params
    c_params = production? ? prod_params : dev_params

    at = config_template.appliance_type

    c_params[:appliance_type_id] = at.id
    c_params[:name] ||= at.name
    c_params[:description] ||= at.description
    c_params[:compute_sites] = allowed_compute_sites

    c_params
  end

  def prod_params
    params.permit(
      :appliance_set_id,
      :name, :description,
      :compute_site_ids)
  end

  def dev_params
    params.permit(
      :appliance_set_id,
      :user_key_id,
      :name, :description,
      :compute_site_ids)
  end

  def allowed_compute_sites
    if params[:compute_site_ids].blank?
      ComputeSite.active
    else
      ComputeSite.where(id: params[:compute_site_ids], active: true)
    end
  end

  def apply_preferences
    preferences && appliance.create_dev_mode_property_set(preferences)
  end

  def init_billing
    # Add Time.now.utc() as prepaid_until - this effectively means that the appliance is unpaid.
    # The requestor must bill this new appliance prior to exposing it to the end user.
    appliance.prepaid_until = Time.now.utc
  end

  def preferences
    params.permit(dev_mode_property_set: [:preference_memory, :preference_cpu, :preference_disk])[:dev_mode_property_set] unless production?
  end

  def init_appliance_configuration
    appliance.appliance_configuration_instance = configuration_instance
  end

  def check_for_at_instantiation_possibility!
    raise CanCan::AccessDenied unless can_create_appliance?
  end

  def can_create_appliance?
    type = appliance.appliance_type
    visible_to = type.visible_to

    case visible_to.to_sym
      when :owner     then appliance.appliance_set.user == type.author
      when :developer then appliance.appliance_set.appliance_set_type.development?
      else true
    end
  end

  def production?
    appliance_set.production?
  end

  def appliance_set
    @appliance_set ||= ApplianceSet.find(appliance_set_id)
  end

  def appliance_set_id
    params.permit(:appliance_set_id)[:appliance_set_id]
  end

  def config_template
    @config_template ||= ApplianceConfigurationTemplate.find(config_template_id)
  end

  def config_template_id
    params[:configuration_template_id]
  end

  def configuration_instance
    @config_instance ||= ApplianceConfigurationInstance.get(config_template, config_params)
  end

  def config_params
    c_params = params[:params] || {}
    c_params[Air.config.mi_authentication_key] = mi_authentication_key
    c_params
  end
end