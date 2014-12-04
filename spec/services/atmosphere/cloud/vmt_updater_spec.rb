require 'rails_helper'

describe Atmosphere::Cloud::VmtUpdater do

  it 'openstack updates VMT--AT relation when VMT is young' do
    at, source_vmt, source_cs = at_with_vmt_on_cs
    target_cs = create(:compute_site)
    image = open_stack_image('target_vmt_id',
      source_cs.site_id, source_vmt.id_at_site)
    updater = Atmosphere::Cloud::VmtUpdater.new(target_cs, image)

    updater.update
    target_vmt = Atmosphere::VirtualMachineTemplate.find_by(id_at_site: 'target_vmt_id')

    expect(target_vmt.appliance_type).to eq at
    expect(target_vmt.managed_by_atmosphere).to be_truthy
  end

  it 'amazon updates VMT--AT relation when VMT is young' do
    at, source_vmt, source_cs = at_with_vmt_on_cs
    target_cs = create(:compute_site)
    image = Fog::Compute::AWS::Image.new({
      id: 'ami-123',
      name: 'vmt',
      state: 'available',
      architecture: 'x86_64',
      tags: {
        'source_cs' => source_cs.site_id,
        'source_uuid' => source_vmt.id_at_site
      }
    })
    updater = Atmosphere::Cloud::VmtUpdater.new(target_cs, image)

    updater.update
    target_vmt = Atmosphere::VirtualMachineTemplate.find_by(id_at_site: 'ami-123')

    expect(target_vmt.appliance_type).to eq at
    expect(target_vmt.managed_by_atmosphere).to be_truthy
  end

  it 'updates VMT version when it is migrated from other compute site' do
    _, source_vmt, source_cs = at_with_vmt_on_cs
    target_cs = create(:compute_site)
    image = open_stack_image('target_vmt_id',
                             source_cs.site_id,
                             source_vmt.id_at_site)
    updater = Atmosphere::Cloud::VmtUpdater.new(target_cs, image)

    source_vmt.version = 13
    source_vmt.save

    updater.update
    target_vmt = Atmosphere::VirtualMachineTemplate.
                  find_by(id_at_site: 'target_vmt_id')

    expect(target_vmt.version).to eq 13
  end

  it 'does not update VMT--AT relation when VMT is old' do
    at, source_vmt, source_cs = at_with_vmt_on_cs
    target_cs = create(:compute_site)
    image = open_stack_image('target_vmt_id',
      source_cs.site_id, source_vmt.id_at_site)
    updater = Atmosphere::Cloud::VmtUpdater.new(target_cs, image)
    target_vmt = create(:virtual_machine_template,
      compute_site: target_cs,
      id_at_site: 'target_vmt_id',
      created_at: (Atmosphere.vmt_at_relation_update_period + 1).hours.ago)

    updater.update
    target_vmt = Atmosphere::VirtualMachineTemplate.find_by(id_at_site: 'target_vmt_id')

    expect(target_vmt.appliance_type).to be_nil
  end

  it 'does not set relation when source VMT does not exist' do
    source_cs = create(:compute_site)
    target_cs = create(:compute_site)
    image = open_stack_image('target_vmt_id',
      source_cs.site_id, 'does_not_exist')
    updater = Atmosphere::Cloud::VmtUpdater.new(target_cs, image)

    updater.update
    target_vmt = Atmosphere::VirtualMachineTemplate.find_by(id_at_site: 'target_vmt_id')

    expect(target_vmt.appliance_type).to be_nil
  end

  it 'does not set relation to AT when CS does not exist' do
    target_cs = create(:compute_site)
    image = open_stack_image('target_vmt_id',
      'does_not_exist', 'does_not_exist')
    updater = Atmosphere::Cloud::VmtUpdater.new(target_cs, image)

    updater.update
    target_vmt = Atmosphere::VirtualMachineTemplate.find_by(id_at_site: 'target_vmt_id')

    expect(target_vmt.appliance_type).to be_nil
  end

  it 'triggers removing old VMT after state changed into active' do
    target_cs = create(:compute_site)
    image = open_stack_image('id', nil, nil)
    updater = Atmosphere::Cloud::VmtUpdater.new(target_cs, image)

    expect(Atmosphere::Cloud::RemoveOlderVmtWorker).
      to receive(:perform_async)

    updater.update
  end

  it 'does not remove old VMT when old state is ACTIVE' do
    target_cs = create(:compute_site)
    image = open_stack_image('id', nil, nil)
    create(:virtual_machine_template,
           id_at_site: 'id',
           state: :active,
           compute_site: target_cs)
    updater = Atmosphere::Cloud::VmtUpdater.new(target_cs, image)

    expect(Atmosphere::Cloud::RemoveOlderVmtWorker).
      to_not receive(:perform_async)

    updater.update
  end

  it 'does not remove old VMT when new status is different than ACTIVE' do
    target_cs = create(:compute_site)
    image = open_stack_image('id', nil, nil)
    image.status = 'BUILD'
    updater = Atmosphere::Cloud::VmtUpdater.new(target_cs, image)

    expect(Atmosphere::Cloud::RemoveOlderVmtWorker).
      to_not receive(:perform_async)

    updater.update
  end

  def open_stack_image(image_id, source_cs, source_uuid)
    Fog::Compute::OpenStack::Image.new({
      id: image_id,
      name: 'vmt',
      status: 'ACTIVE',
      service: double(list_metadata:
        double(body: {'metadata' => {
          'source_cs' => source_cs,
          'source_uuid' => source_uuid
          }})
        )
      })
  end

  def at_with_vmt_on_cs
    at = create(:appliance_type)
    source_cs = create(:compute_site, site_id: 'source_cs')
    source_vmt = create(:virtual_machine_template,
      id_at_site: 'source_vmt_id',
      appliance_type: at,
      compute_site: source_cs)

    [at, source_vmt, source_cs]
  end
end
