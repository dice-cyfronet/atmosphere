# == Schema Information
#
# Table name: appliance_types
#
#  id                :integer          not null, primary key
#  name              :string(255)      not null
#  description       :text
#  shared            :boolean          default(FALSE), not null
#  scalable          :boolean          default(FALSE), not null
#  visibility        :string(255)      default("under_development"), not null
#  preference_cpu    :float
#  preference_memory :integer
#  preference_disk   :integer
#  security_proxy_id :integer
#  user_id           :integer
#  created_at        :datetime
#  updated_at        :datetime
#

class ApplianceType < ActiveRecord::Base
  extend Enumerize

  belongs_to :security_proxy
  belongs_to :author, :class_name => 'User', :foreign_key => 'user_id'

  has_many :appliances
  has_many :port_mapping_templates, dependent: :destroy
  has_many :appliance_configuration_templates, dependent: :destroy

  validates_presence_of :name, :visibility
  validates_uniqueness_of :name

  # TODO Perhaps explicit default here is not needed when we have it in migrations; test and remove
  #enumerize :visibility, in: [:under_development, :unpublished, :published], default: :under_development
  enumerize :visibility, in: [:under_development, :unpublished, :published]

  validates :visibility, inclusion: %w(under_development unpublished published)
  validates :shared, inclusion: [true, false]
  validates :scalable, inclusion: [true, false]

  validates :preference_memory, numericality: { only_integer: true, greater_than_or_equal_to: 0, allow_nil: true }
  validates :preference_disk, numericality: { only_integer: true, greater_than_or_equal_to: 0, allow_nil: true }
  validates :preference_cpu, numericality: { greater_than_or_equal_to: 0.0, allow_nil: true }

end
