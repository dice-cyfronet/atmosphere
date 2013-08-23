# == Schema Information
#
# Table name: compute_sites
#
#  id         :integer          not null, primary key
#  site_id    :string(255)
#  name       :string(255)
#  location   :string(255)
#  site_type  :string(255)
#  created_at :datetime
#  updated_at :datetime
#

require 'spec_helper'

describe ComputeSite do
  pending "add some examples to (or delete) #{__FILE__}"
end
