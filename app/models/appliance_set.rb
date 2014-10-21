# == Schema Information
#
# Table name: appliance_sets
#
#  id                 :integer          not null, primary key
#  name               :string(255)
#  priority           :integer          default(50), not null
#  appliance_set_type :string(255)      default("workflow"), not null
#  user_id            :integer          not null
#  created_at         :datetime
#  updated_at         :datetime
#

class ApplianceSet < ActiveRecord::Base
  extend Enumerize

  belongs_to :user

  validates_presence_of :priority, :appliance_set_type, :user

  validates :priority, numericality: { only_integer: true }, inclusion: 1..100

  enumerize :appliance_set_type, in: [:portal, :development, :workflow]
  validates :appliance_set_type, inclusion: %w(portal development workflow)
  validates :appliance_set_type, uniqueness: { scope: :user }, if: 'appliance_set_type == "development" or appliance_set_type == "portal"'

  attr_readonly :appliance_set_type

  has_many :appliances, dependent: :destroy

  scope :with_vm, ->(virtual_machine) { joins(appliances: :virtual_machines).where(virtual_machines: {id: virtual_machine.id}) }

  scope :clew_appliances, -> (appliance_set_type) { where(:appliance_sets => { :appliance_set_type => appliance_set_type }).
      includes(:appliances).references(:appliances).
      includes(:appliances => :deployments).references(:appliances => :deployments).
      includes(:appliances => :http_mappings).references(:appliances => :http_mappings).
      includes(:appliances => { :http_mappings => :port_mapping_template } ).references(:appliances => { :http_mappings => :port_mapping_template } ).
      includes(:appliances => { :deployments => :virtual_machine }).references(:appliances => { :deployments => :virtual_machine }).
      includes(:appliances => { :http_mappings => { :port_mapping_template => :endpoints } } ).references(:appliances => { :http_mappings => { :port_mapping_template => :endpoints } }).
      includes(:appliances => { :deployments => { :virtual_machine => :port_mappings } } ).references(:appliances => { :deployments => { :virtual_machine => :port_mappings } }).
      includes(:appliances => { :deployments => { :virtual_machine => :compute_site } } ).references(:appliances => { :deployments => { :virtual_machine => :compute_site } }).
      includes(:appliances => { :deployments => { :virtual_machine => :virtual_machine_flavor } }).references(:appliances => { :deployments => { :virtual_machine => :virtual_machine_flavor } })}

  def production?
    not appliance_set_type.development?
  end

end
