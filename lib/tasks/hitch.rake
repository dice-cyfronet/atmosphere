namespace :compute do
  desc "Hitch VMs to Appliance Types"
  task hitch: :environment do
    ComputeSite.all.each do |site|
      filters = site.template_filters ? JSON.parse(site.template_filters) : nil
      images = site.cloud_client.images.all(filters)

      all_site_templates = site.virtual_machine_templates.to_a
      images.each do |image|
        updated_vmt = Cloud::VmtUpdater.new(site, image, all: true).update

        all_site_templates.delete(updated_vmt)
      end

      #remove deleted templates
      all_site_templates.each do |vmt|
        vmt.destroy(false) if vmt.old?
      end
    end
  end
end
