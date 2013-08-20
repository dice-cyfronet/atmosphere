class ApplianceType < ActiveRecord::Base

  validates_presence_of :name, :visibility
  validates_uniqueness_of :name

  validates :visibility, inclusion: %w(under_development unpublished published)
  validates :shared, inclusion: [true, false]
  validates :scalable, inclusion: [true, false]

end
