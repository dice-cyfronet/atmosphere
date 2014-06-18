require 'rails_helper'

describe Cloud::VmCreator do
  let(:default_flavor) { build(:virtual_machine_flavor, id_at_site: 'def_f_id') }
  let(:cs) do
    build(:compute_site).tap do |cs|
      cs.virtual_machine_flavors = [
        default_flavor
      ]
    end
  end
  let(:vmt) { build(:virtual_machine_template, compute_site: cs, id_at_site: 'vmt_id',
    appliance_type: build(:appliance_type)) }

  let(:servers_cloud_client) { double('server cloud client') }
  let(:cloud_client) { double('cloud_client', servers: servers_cloud_client) }

  let(:server_id) { 'server_id' }
  let(:server) { double('server', id: server_id) }

  before do
    allow(cs).to receive(:cloud_client).and_return(cloud_client)
  end

  it 'creates VM' do
    allow(servers_cloud_client).to receive(:create).and_return(server)
    vm_id_at_site = Cloud::VmCreator.new(vmt).spawn_vm!

    expect(vm_id_at_site).to eq server_id
  end

  it 'creates VM with correct VMT id' do
    expect(servers_cloud_client).to receive(:create) do |params|
      expect(params[:image_ref]).to eq vmt.id_at_site
      expect(params[:image_id]).to eq vmt.id_at_site
    end.and_return(server)

    Cloud::VmCreator.new(vmt).spawn_vm!
  end

  it 'creates VM with default flavor' do
    expect(servers_cloud_client).to receive(:create) do |params|
      expect(params[:flavor_ref]).to eq default_flavor.id_at_site
      expect(params[:flavor_id]).to eq default_flavor.id_at_site
    end.and_return(server)

    Cloud::VmCreator.new(vmt).spawn_vm!
  end

  it 'creates VM with default name' do
    expect(servers_cloud_client).to receive(:create) do |params|
      expect(params[:name]).to eq vmt.name
    end.and_return(server)

    Cloud::VmCreator.new(vmt).spawn_vm!
  end

  it 'creates VM with custom name' do
    expect(servers_cloud_client).to receive(:create) do |params|
      expect(params[:name]).to eq 'custom name'
    end.and_return(server)

    Cloud::VmCreator.new(vmt, name: 'custom name').spawn_vm!
  end

  it 'creates VM with user data' do
    expect(servers_cloud_client).to receive(:create) do |params|
      expect(params[:user_data]).to eq 'my user data'
    end.and_return(server)

    Cloud::VmCreator.new(vmt, user_data: 'my user data').spawn_vm!
  end

  it 'creates VM without user data when it is empty' do
    expect(servers_cloud_client).to receive(:create) do |params|
      expect(params).to_not include :user_data
    end.and_return(server)

    Cloud::VmCreator.new(vmt, user_data: nil).spawn_vm!
  end

  it 'creates VM with user key' do
    user_key = double(id_at_site: 'my_key_name')
    expect(user_key).to receive(:import_to_cloud).with(cs)
    expect(servers_cloud_client).to receive(:create) do |params|
      expect(params[:key_name]).to eq 'my_key_name'
    end.and_return(server)

    Cloud::VmCreator.new(vmt, user_key: user_key).spawn_vm!
  end

  context 'amazon' do
    before do
      cs.technology = 'aws'

      allow(servers_cloud_client).to receive(:create).and_return(server)
    end

    it 'creates VM in "mniec_permit_all" secrutiry group' do
      expect(servers_cloud_client).to receive(:create) do |params|
        expect(params[:groups]).to include 'mniec_permit_all'
      end.and_return(server)

      Cloud::VmCreator.new(vmt).spawn_vm!
    end
  end
end