class Atmosphere::MigrationJobDecorator < Draper::Decorator
  delegate_all

  def appliance_type_name
    if object.appliance_type
      object.appliance_type.name
    else
      'unknown'
    end
  end

  def virtual_machine_template_name
    if object.virtual_machine_template
      object.virtual_machine_template.name
    else
      'unknown'
    end
  end

  def virtual_machine_template_id_at_site
    if object.virtual_machine_template
      object.virtual_machine_template.id_at_site
    else
      'unknown'
    end
  end

  def compute_site_source_name
    if object.compute_site_source
      object.compute_site_source.name
    else
      'unknown'
    end
  end

  def compute_site_destination_name
    if object.compute_site_destination
      object.compute_site_destination.name
    else
      'unknown'
    end
  end

  def status_last_line
    if object.status
      object.status.lines.last
    else
      'unknown'
    end
  end
end
