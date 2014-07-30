
class ClewApplianceTypesSerializer < ActiveModel::Serializer

  attribute :appliance_types

  attribute :compute_sites

  def appliance_types
    object[:appliance_types].map { |at| map_at(at) }
  end

  def map_at(at)
    options = {}
    options[:cpu] &&= at.preference_cpu
    options[:memory] &&= at.preference_memory
    options[:hdd] &&= at.preference_disk
    flavor = VirtualMachineFlavor.with_prefs(options).first
    {
      :id => at.id,
      :name => at.name,
      :description => at.description,
      :preference_cpu => at.preference_cpu,
      :preference_memory => at.preference_memory,
      :preference_disk => at.preference_disk,
      :matched_flavor  => flavor,
      :compute_site_ids => at.compute_site_ids,
      :appliance_configuration_templates => at.appliance_configuration_templates
    }
  end

  def compute_sites
    compute_sites = {}
    object[:appliance_types].each do |at|
      at.compute_sites.each do |cs|
        compute_sites[cs.id] ||= cs
      end
    end
    compute_sites.values.map { |cs| map_cs(cs) }
  end

  def map_cs(cs)
    { :id => cs.id,
      :site_id => cs.site_id,
      :name => cs.name,
      :location => cs.location,
      :site_type => cs.site_type,
      :technology => cs.technology,
      :http_proxy_url => cs.http_proxy_url,
      :https_proxy_url => cs.https_proxy_url,
      :template_filters => cs.template_filters,
      :active => cs.active
    }
  end

end




