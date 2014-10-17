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
end