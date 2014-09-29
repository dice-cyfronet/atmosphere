module Atmosphere
  class PmtCopier
    def self.copy(object_with_pmt)
      object_with_pmt.port_mapping_templates.collect do |pmt|
        copy = pmt.dup
        copy.appliance_type = nil
        copy.dev_mode_property_set = nil
        copy.endpoints = pmt.endpoints.collect(&:dup)
        copy.port_mapping_properties = pmt.port_mapping_properties.collect(&:dup)
        copy.port_mapping_properties.each { |pmp| pmp.port_mapping_template = copy }
        copy
      end if object_with_pmt
    end
  end
end