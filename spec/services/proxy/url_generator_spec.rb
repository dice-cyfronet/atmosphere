require 'spec_helper'

describe Proxy::UrlGenerator do
  describe '#url_for' do
    let(:cs) do
      build(:compute_site,
        http_proxy_url: 'http://http.proxy',
        https_proxy_url: 'https://https.proxy')
    end

    let(:appliance) do
      appl = build(:appliance)
      appl.id = 1
      appl
    end

    let(:pmt) { build(:port_mapping_template, service_name: 'service_name') }

    let(:mapping) do
      build(:http_mapping,
      appliance: appliance,
      port_mapping_template: pmt)
    end

    subject { Proxy::UrlGenerator.new(cs) }

    it 'generate http proxy url for http mapping' do
      mapping.application_protocol = :http
      expect(subject.url_for(mapping)).to eq 'http://service_name.1.http.proxy'
    end

    it 'generate https proxy url for https mapping' do
      mapping.application_protocol = :https
      expect(subject.url_for(mapping)).to eq 'https://service_name.1.https.proxy'
    end
  end
end