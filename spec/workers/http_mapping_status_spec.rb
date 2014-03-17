require 'spec_helper'

describe 'My behaviour' do

  include ApiHelpers


  let(:hm) { create(:http_mapping) }

  it 'should do something' do
    puts "#{hm}"

    puts "#{hm.id}"
    hm.save

    maping = HttpMapping.find_by id: hm.id

    puts "#{maping.id}"
  end
end