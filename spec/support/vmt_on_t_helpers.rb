module VmtOnTHelpers
  def vmt_on_tenant(options = {})
    t = create(:tenant, active: options[:t_active])
    vmt = create(:virtual_machine_template, tenant: t)

    [t, vmt]
  end
end
