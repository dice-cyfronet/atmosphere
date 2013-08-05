require 'spec_helper'

INVALID_FACTORIES = []

FactoryGirl.factories.map(&:name).each do |factory_name|
  next if INVALID_FACTORIES.include?(factory_name)
  describe "#{factory_name} factory" do
    it 'expect factory to be valid' do
      expect(build(factory_name)).to be_valid
    end
  end
end