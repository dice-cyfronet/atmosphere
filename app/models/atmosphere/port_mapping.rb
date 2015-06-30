# == Schema Information
#
# Table name: port_mappings
#
#  id                       :integer          not null, primary key
#  public_ip                :string(255)      not null
#  source_port              :integer          not null
#  port_mapping_template_id :integer          not null
#  virtual_machine_id       :integer          not null
#  created_at               :datetime
#  updated_at               :datetime
#
module Atmosphere
  class PortMapping < ActiveRecord::Base
    belongs_to :virtual_machine,
      class_name: 'Atmosphere::VirtualMachine'

    belongs_to :port_mapping_template,
      class_name: 'Atmosphere::PortMappingTemplate'

    validates :public_ip,
              presence: true

    validates :virtual_machine,
              presence: true

    validates :port_mapping_template,
              presence: true

    validates :source_port,
              presence: true,
              numericality: {
                only_integer: true,
                greater_than_or_equal_to: 0
              }

    before_destroy :delete_dnat

    private
    def delete_dnat
      virtual_machine.tenant.dnat_client.remove_port_mapping(self)
    end

  end
end
