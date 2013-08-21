class ApplianceType < ActiveRecord::Base
  extend Enumerize

  belongs_to :security_proxy
  belongs_to :author, :class_name => 'User', :foreign_key => 'user_id'

  has_many :appliances

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
