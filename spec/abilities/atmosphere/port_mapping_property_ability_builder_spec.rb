require 'rails_helper'

describe Atmosphere::PortMappingPropertyAbilityBuilder do
  let(:user) { build(:user) }
  let(:pdp) { double('pdp') }
  let(:pdp_class) { double('pdp class') }
  let(:ability) { Atmosphere::Ability.new(user) }

  before do
    allow(Atmosphere).to receive(:at_pdp).with(user).and_return(pdp)
    user.id = 1
  end

  let(:at)  { build(:appliance_type) }
  let(:pmt) { build(:port_mapping_template, appliance_type: at) }
  let(:pmp) { build(:port_mapping_property, port_mapping_template: pmt) }

  it 'allows to manage PMP when pdp allows for it' do
    allow(pdp).to receive(:can_manage?).with(at).and_return(true)

    expect(ability.can?(:create, pmp)).to be_truthy
    expect(ability.can?(:update, pmp)).to be_truthy
    expect(ability.can?(:destroy, pmp)).to be_truthy
  end

  it ' does not allow to manage PMP when pdp does not allow for it' do
    allow(pdp).to receive(:can_manage?).with(at).and_return(false)

    expect(ability.can?(:create, pmp)).to be_falsy
    expect(ability.can?(:update, pmp)).to be_falsy
    expect(ability.can?(:destroy, pmp)).to be_falsy
  end

  context 'not in development mode' do
    it 'check in pdp if appliance type can be managed' do
      expect(pdp).to receive(:can_manage?).exactly(3).times.with(at)

      ability.can?(:create, pmp)
      ability.can?(:update, pmp)
      ability.can?(:destroy, pmp)
    end
  end

  context 'development mode' do
    it 'check in pdp if dev mode property set can be managed' do
      appl_set = build(:dev_appliance_set, user: user)
      dev_appl = build(:appliance, appliance_set: appl_set)
      dev_mode_property_set = build(:dev_mode_property_set, appliance: dev_appl)
      dev_pmt = build(
        :dev_port_mapping_template,
        dev_mode_property_set: dev_mode_property_set
      )
      dev_pmp = build(:port_mapping_property, port_mapping_template: dev_pmt)

      expect(pdp).to receive(:can_manage?).exactly(3).times.
        with(dev_mode_property_set)
      ability.can?(:create, dev_pmp)
      ability.can?(:update, dev_pmp)
      ability.can?(:destroy, dev_pmp)
    end
  end
end