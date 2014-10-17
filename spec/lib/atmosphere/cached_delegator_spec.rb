require 'spec_helper'
require 'atmosphere/cached_delegator'

require "#{File.dirname(__FILE__)}/../../support/time_helper.rb"


describe Atmosphere::CachedDelegator do
  include TimeHelper

  subject { Atmosphere::CachedDelegator.new(5) { SecureRandom.base64 } }

  it 'returns cached value' do
    previous = subject.to_s
    expect(previous).to eq subject.to_s
  end

  it 'creates new value when timeout' do
    previous = subject.to_s

    time_travel(10)

    expect(previous).not_to eq subject.to_s
  end

  it 'resets cached value' do
    previous = subject.to_s

    subject.clean_cache!

    expect(previous).not_to eq subject.to_s
  end
end