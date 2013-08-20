require 'spec_helper'

describe Appliance do
  expect_it { to belong_to :appliance_set }
  expect_it { to belong_to :appliance_type }
end
