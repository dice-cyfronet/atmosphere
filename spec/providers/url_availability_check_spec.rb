require 'spec_helper'

describe UrlAvailabilityCheck do
  let(:stubs) { Faraday::Adapter::Test::Stubs.new }
  let(:url) { 'http://foo.bar' }

  before do
    connection = Faraday.new do |builder|
      builder.adapter :test, stubs
    end

    allow(Faraday).to receive(:new).and_return(connection)
  end

  it 'returns true when resource is availabe (200 response code)' do
    respond_with(200)

    expect(subject.is_available(url)).to be_true
  end

  it 'returns true if resource does not exist (404 response code)' do
    respond_with(404)

    expect(subject.is_available(url)).to be_true
  end

  it 'returns false if bad gateway (502 response code)' do
    respond_with(502)

    expect(subject.is_available(url)).to be_false
  end

  it 'returns false if any error occurs' do
    stubs.get(url) { fail StandardError }

    expect(subject.is_available(url)).to be_false
  end

  def respond_with(response_code)
    stubs.get(url) { [response_code, {}, 'response body'] }
  end
end