require 'spec_helper'

describe Appliance do

  expect_it { to belong_to :appliance_set }
  expect_it { to validate_presence_of :appliance_set }

  expect_it { to belong_to :appliance_type }
  expect_it { to validate_presence_of :appliance_type }

end
