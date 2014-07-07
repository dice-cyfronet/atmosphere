require 'spec_helper'
require 'mi_resource_access'

describe MiResourceAccess do
  let(:stubs) { Faraday::Adapter::Test::Stubs.new }
  let(:connection) do
    Faraday.new do |builder|
      builder.adapter :test, stubs
    end
  end

  subject { MiResourceAccess.new('AtomicService', connection: connection) }

  context '#has_role?' do
    let(:url) { '/api/hasrole/?local_id=1&type=AtomicService&role=reader' }

    it 'has a role' do
      stubs.get(url) { [200, {}, 'true'] }
      has_role = subject.has_role?(1, :reader)

      expect(has_role).to be_truthy
    end

    it 'does not have a role' do
      stubs.get(url) { [200, {}, 'false'] }
      has_role = subject.has_role?(1, :reader)

      expect(has_role).to be_falsy
    end

    it 'does not have a role when invalid ticket' do
      stubs.get(url) { [401, {}, 'true'] }
      has_role = subject.has_role?(1, :reader)

      expect(has_role).to be_falsy
    end

    it 'does not have a role when resource not registered in mi' do
      stubs.get(url) { [404, {}, 'true'] }
      has_role = subject.has_role?(1, :reader)

      expect(has_role).to be_falsy
    end

    it 'does not have a role when internal master interface error' do
      stubs.get(url) { [500, {}, 'true'] }
      has_role = subject.has_role?(1, :reader)

      expect(has_role).to be_falsy
    end
  end

  context '#availabe_resource_ids' do
    let(:url) { '/api/resources?type=AtomicService&role=reader' }

    it 'has 3 resources available' do
      stubs.get(url) { [200, {}, resources(1, 2, 3)] }

      expect(subject.availabe_resource_ids(:reader)).to eq [1, 2, 3]
    end

    it 'has no resources when ticket is not valid' do
      stubs.get(url) { [401, {}, resources(1)] }

      expect(subject.availabe_resource_ids(:reader)).to eq []
    end

    it 'has no resources when internal master interface error' do
      stubs.get(url) { [500, {}, resources(1)] }

      expect(subject.availabe_resource_ids(:reader)).to eq []
    end
  end

  def resources(*ids)
    ids.collect do |id|
      {"local_id" => id, "global_id" => "#{id}_global"}
    end.to_json
  end
end