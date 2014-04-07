require 'spec_helper'

describe Ability do

  let(:user) { build(:user) }
  let(:pdp) { double('pdp') }
  let(:pdp_class) { double('pdp class') }
  let(:ability) { Ability.new(user) }

  before do
    allow(Air.config).to receive(:at_pdp_class).and_return(pdp_class)
    allow(pdp_class).to receive(:new).with(user).and_return(pdp)
    user.id = 1
  end

  context 'with appliance' do
    let(:at) { build(:appliance_type) }

    it 'starts appl in production when pdp allows it' do
      appl = start_appl(:portal, :can_start_in_production?, true)

      expect(ability.can?(:create, appl)).to be_true
    end

    it 'does not allow to start AT in production when pdp does not allow it' do
      appl = start_appl(:portal, :can_start_in_production?, false)

      expect(ability.can?(:create, appl)).to be_false
    end

    it 'starts appl in development when pdp allows it' do
      appl = start_appl(:development, :can_start_in_development?, true)

      expect(ability.can?(:create, appl)).to be_true
    end

    it 'does not allow to start AT in development when pdp does not allow it' do
      appl = start_appl(:development, :can_start_in_development?, false)

      expect(ability.can?(:create, appl)).to be_false
    end
  end

  context 'with appliance type' do
    let(:at) { build(:appliance_type) }

    it 'allows to update/destroy AT when user is a AT manager according to pdp' do
      allow(pdp).to receive(:can_manage?).with(at).and_return(true)

      expect(ability.can?(:update, at)).to be_true
      expect(ability.can?(:destroy, at)).to be_true
    end

    it 'does not allow to update/destroy AT when user is a AT manager according to pdp' do
      allow(pdp).to receive(:can_manage?).with(at).and_return(false)

      expect(ability.can?(:update, at)).to be_false
      expect(ability.can?(:destroy, at)).to be_false
    end
  end

  context 'with port mapping template' do
    let(:at) { build(:appliance_type) }
    let(:pmt) { build(:port_mapping_template, appliance_type: at) }

    it 'allows to manage PMT assigned to AT where user is a manager according to pdp' do
      allow(pdp).to receive(:can_manage?).with(at).and_return(true)

      expect(ability.can?(:create, pmt)).to be_true
      expect(ability.can?(:update, pmt)).to be_true
      expect(ability.can?(:destroy, pmt)).to be_true
    end

    it 'does not allow to manage PMT assigned to AT where user is a manager according to pdp' do
      allow(pdp).to receive(:can_manage?).with(at).and_return(false)

      expect(ability.can?(:create, pmt)).to be_false
      expect(ability.can?(:update, pmt)).to be_false
      expect(ability.can?(:destroy, pmt)).to be_false
    end
  end

  context 'with endpoint' do
    let(:at) { build(:appliance_type) }
    let(:pmt) { build(:port_mapping_template, appliance_type: at) }
    let(:endpoint) { build(:endpoint, port_mapping_template: pmt) }

    it 'allows to manage endpoint assigned to AT where user is a manager according to pdp' do
       allow(pdp).to receive(:can_manage?).with(at).and_return(true)

       expect(ability.can?(:create, endpoint)).to be_true
       expect(ability.can?(:update, endpoint)).to be_true
       expect(ability.can?(:destroy, endpoint)).to be_true
     end

     it 'does not allow to manage endpoint assigned to AT where user is a manager according to pdp' do
       allow(pdp).to receive(:can_manage?).with(at).and_return(false)

       expect(ability.can?(:create, endpoint)).to be_false
       expect(ability.can?(:update, endpoint)).to be_false
       expect(ability.can?(:destroy, endpoint)).to be_false
     end
  end

  context 'with initial configuration template' do
    let(:at) { build(:appliance_type) }
    let(:act) { build(:appliance_configuration_template, appliance_type: at) }

    it 'allows to manage ACT assigned to AT where user is a manager according to pdp' do
       allow(pdp).to receive(:can_manage?).with(at).and_return(true)

       expect(ability.can?(:create, act)).to be_true
       expect(ability.can?(:update, act)).to be_true
       expect(ability.can?(:destroy, act)).to be_true
     end

     it 'does not allow to manage ACT assigned to AT where user is a manager according to pdp' do
       allow(pdp).to receive(:can_manage?).with(at).and_return(false)

       expect(ability.can?(:create, act)).to be_false
       expect(ability.can?(:update, act)).to be_false
       expect(ability.can?(:destroy, act)).to be_false
     end
  end

  def start_appl(type, pdp_method_sym, pdp_response)
    appl = build(:appliance, appliance_set: build_as(type), appliance_type: at)
    allow(pdp).to receive(pdp_method_sym).with(at).and_return(pdp_response)
    appl
  end

  def build_as(type)
    as = build(:appliance_set, user: user, appliance_set_type: type)
    as.user_id = user.id
    as
  end
end