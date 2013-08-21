class ComputeSite < ActiveRecord::Base
  extend Enumerize

  enumerize :site_type, in: [:public, :private], predicates: true
  validates :site_type, inclusion: %w(public private) 

end
