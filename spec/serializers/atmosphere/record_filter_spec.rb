require 'rspec'
require "spec_helper"

require "active_model_serializers"
require "active_support/json"

describe Atmosphere::RecordFilter do

  class CustomSerializer
    include Atmosphere::RecordFilter
    can_filter_by :a, :c
  end

  it "captures the specified filters" do
    expect(CustomSerializer.serializable_filters).to be_an Array
    expect(CustomSerializer.serializable_filters.size).to eq 2
    expect(CustomSerializer.serializable_filters[0]).to eq :a
    expect(CustomSerializer.serializable_filters[1]).to eq :c
  end

end