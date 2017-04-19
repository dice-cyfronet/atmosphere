require 'rails_helper'

describe Atmosphere::ApplianceAbilityBuilder do
  let(:user) { build(:user) }
  let(:pdp) { double('pdp') }
  let(:pdp_class) do
    pdp_class = double('pdp_class')
    allow(pdp_class).to receive(:new).and_return(pdp)
    pdp_class
  end
  let(:ability) { Atmosphere::Ability.new(user, true, pdp_class) }
  let(:at) { build(:appliance_type, visible_to: :all) }

  before do
    allow(Atmosphere).to receive(:at_pdp).with(user).and_return(pdp)
  end

  it 'cannot start dev AT in production mode' do
    at = build(:appliance_type, visible_to: :developer)
    appl = start_appl(:portal, at)

    expect(ability.can?(:create, appl)).to be_falsy
  end

  it 'cannot start not owned private AT' do
    at = build(:appliance_type, visible_to: :owner)
    appl = start_appl(:portal, at)

    expect(ability.can?(:create, appl)).to be_falsy
  end

  it 'starts appl in production when pdp allows it' do
    appl = start_appl(:portal, at, :can_start_in_production?, true)

    expect(ability.can?(:create, appl)).to be_truthy
  end

  it 'does not allow to start AT in production when pdp does not allow it' do
    appl = start_appl(:portal, at, :can_start_in_production?, false)

    expect(ability.can?(:create, appl)).to be_falsy
  end

  it 'starts appl in development when pdp allows it' do
    appl = start_appl(:development, at, :can_start_in_development?, true)

    expect(ability.can?(:create, appl)).to be_truthy
  end

  it 'does not allow to start AT in development when pdp does not allow it' do
    appl = start_appl(:development, at, :can_start_in_development?, false)

    expect(ability.can?(:create, appl)).to be_falsy
  end

  def start_appl(type, at, pdp_method_sym = nil, pdp_response = nil)
    appl = build(:appliance, appliance_set: build_as(type), appliance_type: at)
    if pdp_method_sym
      allow(pdp).to receive(pdp_method_sym).with(at).and_return(pdp_response)
    end
    appl
  end

  def build_as(type)
    as = build(:appliance_set, user: user, appliance_set_type: type)
    as.user_id = user.id
    as
  end
end
