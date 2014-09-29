require 'rails_helper'

describe Atmosphere::EndpointsVisibleToUser do

  context 'when normal user' do
    let(:user) { create(:user) }
    subject { Atmosphere::EndpointsVisibleToUser.new(user) }

    it 'returns endpoints from AT owned by the user' do
      endpoint = create_endpoint(author: user, visible_to: :owner)

      result = subject.find

      expect(result.count).to eq 1
      expect(result.first).to eq endpoint
    end

    it 'returns endpoints from AT visible to all' do
      endpoint = create_endpoint(visible_to: :all)

      result = subject.find

      expect(result.count).to eq 1
      expect(result.first).to eq endpoint
    end

    it 'does not return endpoints from AT visible to developer' do
      endpoint = create_endpoint(visible_to: :developer)

      result = subject.find

      expect(result.count).to eq 0
    end
  end

  context 'when developer' do
    let(:developer) { create(:developer) }
    subject { Atmosphere::EndpointsVisibleToUser.new(developer) }

    it 'returns endpoints from AT visible to developer' do
      endpoint = create_endpoint(visible_to: :developer)

      result = subject.find

      expect(result.count).to eq 1
    end

    it 'returns endpoints defined in development appliance' do
      as = create(:appliance_set,
        user: developer, appliance_set_type: :development)
      appl = create(:appliance, appliance_set: as)
      pmt = create(:port_mapping_template,
        dev_mode_property_set: appl.dev_mode_property_set,
        appliance_type: nil)
      endpoint = create(:endpoint, port_mapping_template: pmt)

      result = subject.find

      expect(result.count).to eq 1
      expect(result.first).to eq endpoint
    end
  end

  def create_endpoint(options = {})
    at_props = {}
    at_props[:visible_to] = options[:visible_to] if  options[:visible_to]
    at_props[:author] = options[:author] if  options[:author]

    at = create(:appliance_type, at_props)
    pmt = create(:port_mapping_template, appliance_type: at)

    create(:endpoint, port_mapping_template: pmt)
  end
end