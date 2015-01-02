require 'rails_helper'
require 'generator_spec'
require 'generators/atmosphere/install_generator'

describe Atmosphere::Generators::InstallGenerator, type: :generator do
  destination File.expand_path('../../../../tmp', __FILE__)

  before :all do
    prepare_destination
    copy_routes
    run_generator
  end

  it 'creates destination initializer' do
    assert_file 'config/initializers/atmosphere.rb'
  end

  it 'creates clock configuration' do
    assert_file 'app/clock.rb'
  end

  it 'adds atmosphere routes' do
    match = /mount Atmosphere::Engine => "\/"/
    assert_file 'config/routes.rb', match
  end

  def copy_routes
    routes = File.expand_path(
      '../../../../dummy/config/routes.rb.empty', __FILE__)
    destination = File.join(destination_root, 'config')

    FileUtils.mkdir_p(destination)
    FileUtils.cp routes, "#{destination}/routes.rb"
  end
end
