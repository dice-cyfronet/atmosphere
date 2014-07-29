
class ClewApplianceTypesSerializer < ActiveModel::Serializer

  attribute :appliance_types

  attribute :compute_sites

  def appliance_types
    object[:appliance_types].map { |at| map_at(at) }
  end

  def map_at(at)
    at
  end

  def compute_sites
    compute_sites = {}
    object[:appliance_types].each do |at|
      at.compute_sites.each do |cs|
        compute_sites[cs.id] ||= cs
      end
    end
    compute_sites.values
  end

end




