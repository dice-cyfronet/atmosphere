require 'rails_helper'

describe Atmosphere::HttpMappingSerializer do
  it 'returns custom name' do
    hm = create(:http_mapping,
      custom_name: 'my-custom-name',
      base_url: "http://base.url")
    serializer = Atmosphere::HttpMappingSerializer.new(hm)

    result = JSON.parse(serializer.to_json)

    expect(result['http_mapping']['custom_name']).to eq 'my-custom-name'
    expect(result['http_mapping']['custom_url'])
      .to eq 'http://my-custom-name.base.url'
  end
end