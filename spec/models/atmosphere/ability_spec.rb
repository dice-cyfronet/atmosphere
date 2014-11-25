require 'rails_helper'

describe Atmosphere::Ability do

  let(:user) { build(:user) }
  let(:pdp) { double('pdp') }
  let(:pdp_class) { double('pdp class') }
  let(:ability) { Atmosphere::Ability.new(user) }

  before do
    allow(Atmosphere).to receive(:at_pdp).with(user).and_return(pdp)
    user.id = 1
  end

  context 'with appliance type' do
    let(:at) { build(:appliance_type) }

    it 'allows to update/destroy AT when user is a AT manager according to pdp' do
      allow(pdp).to receive(:can_manage?).with(at).and_return(true)

      expect(ability.can?(:update, at)).to be_truthy
      expect(ability.can?(:destroy, at)).to be_truthy
    end

    it 'does not allow to update/destroy AT when user is a AT manager according to pdp' do
      allow(pdp).to receive(:can_manage?).with(at).and_return(false)

      expect(ability.can?(:update, at)).to be_falsy
      expect(ability.can?(:destroy, at)).to be_falsy
    end
  end

  context 'with port mapping template' do
    let(:at) { build(:appliance_type) }
    let(:pmt) { build(:port_mapping_template, appliance_type: at) }

    it 'allows to manage PMT assigned to AT where user is a manager according to pdp' do
      allow(pdp).to receive(:can_manage?).with(at).and_return(true)

      expect(ability.can?(:create, pmt)).to be_truthy
      expect(ability.can?(:update, pmt)).to be_truthy
      expect(ability.can?(:destroy, pmt)).to be_truthy
    end

    it 'does not allow to manage PMT assigned to AT where user is a manager according to pdp' do
      allow(pdp).to receive(:can_manage?).with(at).and_return(false)

      expect(ability.can?(:create, pmt)).to be_falsy
      expect(ability.can?(:update, pmt)).to be_falsy
      expect(ability.can?(:destroy, pmt)).to be_falsy
    end
  end

  context 'with endpoint' do
    let(:at) { build(:appliance_type) }
    let(:pmt) { build(:port_mapping_template, appliance_type: at) }
    let(:endpoint) { build(:endpoint, port_mapping_template: pmt) }

    it 'allows to manage endpoint assigned to AT where user is a manager according to pdp' do
       allow(pdp).to receive(:can_manage?).with(at).and_return(true)

       expect(ability.can?(:create, endpoint)).to be_truthy
       expect(ability.can?(:update, endpoint)).to be_truthy
       expect(ability.can?(:destroy, endpoint)).to be_truthy
     end

     it 'does not allow to manage endpoint assigned to AT where user is a manager according to pdp' do
       allow(pdp).to receive(:can_manage?).with(at).and_return(false)

       expect(ability.can?(:create, endpoint)).to be_falsy
       expect(ability.can?(:update, endpoint)).to be_falsy
       expect(ability.can?(:destroy, endpoint)).to be_falsy
     end
  end

  context 'with initial configuration template' do
    let(:at) { build(:appliance_type) }
    let(:act) { build(:appliance_configuration_template, appliance_type: at) }

    it 'allows to manage ACT assigned to AT where user is a manager according to pdp' do
       allow(pdp).to receive(:can_manage?).with(at).and_return(true)

       expect(ability.can?(:create, act)).to be_truthy
       expect(ability.can?(:update, act)).to be_truthy
       expect(ability.can?(:destroy, act)).to be_truthy
     end

     it 'does not allow to manage ACT assigned to AT where user is a manager according to pdp' do
       allow(pdp).to receive(:can_manage?).with(at).and_return(false)

       expect(ability.can?(:create, act)).to be_falsy
       expect(ability.can?(:update, act)).to be_falsy
       expect(ability.can?(:destroy, act)).to be_falsy
     end
  end
end