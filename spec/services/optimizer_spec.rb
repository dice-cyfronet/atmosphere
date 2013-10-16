require 'spec_helper'

describe Optimizer do

  before do
    Fog.mock!
  end

  subject { Optimizer.instance }

  it 'is not nil' do
     expect(subject).not_to be_nil
  end

  context 'new appliance created' do

    let!(:wf) { create(:workflow_appliance_set) }


    context 'vm can be shared' do
      let!(:shareable_appl_type) { create(:shareable_appliance_type) }


      context 'vm cannot be reused' do

        it 'instantiates a new vm' do
          appl = Appliance.create(appliance_set: wf, appliance_type: shareable_appl_type, appliance_configuration_instance: FactoryGirl.create(:appliance_configuration_instance))

        end

      end

      context 'vm can be reused' do

        it 'reuses available vm' do

        end

      end
    end

    context 'vm cannot be shared' do

      it 'instantiates a new vm' do

      end

    end
  end
end