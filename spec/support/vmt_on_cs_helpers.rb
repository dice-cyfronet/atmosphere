module VmtOnCsHelpers
  def vmt_on_site(options = {})
    cs = create(:compute_site, active: options[:cs_active])
    vmt = create(:virtual_machine_template, compute_site: cs)

    [cs, vmt]
  end
end