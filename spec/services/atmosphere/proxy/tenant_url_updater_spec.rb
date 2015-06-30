require 'rails_helper'

describe Atmosphere::Proxy::TenantUrlUpdater do
  let(:finder) { double('http_mapping_finder') }
  let(:finder_class) { double }

  let(:url_generator) { double('url_generator') }
  let(:url_generator_class) { double }

  let(:t) { double('tenant') }

  before do
    allow(finder_class).to receive(:new).with(t).and_return(finder)
    allow(url_generator_class).to receive(:new).with(t).and_return(url_generator)
  end

  subject do
    Atmosphere::Proxy::TenantUrlUpdater
      .new(t, finder_class, url_generator_class)
  end

  it 'updates all http mappings' do
    mapping1 = build(:http_mapping)
    mapping2 = build(:http_mapping)
    allow(finder).to receive(:find).and_return([mapping1, mapping2])
    allow(url_generator).to receive(:url_for).with(mapping1).and_return('url1')
    allow(url_generator).to receive(:url_for).with(mapping2).and_return('url2')

    subject.update

    expect(mapping1.url).to eq 'url1'
    expect(mapping2.url).to eq 'url2'
  end
end