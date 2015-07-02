class Atmosphere::MigrationJobDecorator < Draper::Decorator
  delegate_all

  def appliance_type_name
    at = object.appliance_type
    at ? at.name : 'unknown'
  end

  def virtual_machine_template_name
    vmt = object.virtual_machine_template
    vmt ? vmt.name : 'unknown'
  end

  def virtual_machine_template_id_at_site
    vmt = object.virtual_machine_template
    vmt ? vmt.id_at_site : 'unknown'
  end

  def tenant_source_name
    css = object.tenant_source
    css ? css.name : 'unknown'
  end

  def tenant_destination_name
    csd = object.tenant_destination
    csd ? csd.name : 'unknown'
  end

  def status_last_line
    s = object.status
    s ? s.lines.last : 'unknown'
  end
end
