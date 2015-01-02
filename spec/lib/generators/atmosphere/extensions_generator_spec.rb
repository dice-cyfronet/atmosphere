require 'rails_helper'
require 'generator_spec'
require 'generators/atmosphere/extensions_generator'

describe Atmosphere::Generators::ExtensionsGenerator, type: :generator do
  destination File.expand_path('../../../../tmp', __FILE__)

  before :all do
    prepare_destination
    run_generator
  end

  it 'copy extension files' do
    assert_file 'app/controllers/concerns/atmosphere/api/v1/'\
                'dev_mode_property_sets_controller_ext.rb'
    assert_file 'app/models/concerns/atmosphere/appliance_type_ext.rb'
    assert_file 'app/serializers/atmosphere/appliance_type_serializer_ext.rb'
  end

  it 'does not copy other concerns' do
    assert_no_file 'app/controllers/concerns/atmosphere/filterable.rb'
    assert_no_file 'app/models/concerns/atmosphere/cloud.rb'
    assert_no_file 'app/serializers/atmosphere/appliance_type_serializer.rb'
  end
end
