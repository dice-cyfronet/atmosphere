require 'rails_helper'

describe VirtualMachineTemplateAbilityBuilder do

  let(:user) { nil }
  subject { Ability.new(user) }

  context 'normal user' do
    let(:user) { build(:user, id: 1) }

    it 'can see VMT assigned to public AT' do
      public_at = build(:appliance_type, visible_to: :all)
      public_vmt = build(:managed_vmt, appliance_type: public_at)

      expect(subject.can?(:read, public_vmt)).to be_truthy
    end

    it 'can see VMT assigned to private owned AT' do
      private_owned_at  = build(:appliance_type,
                                visible_to: :author,
                                user_id: user.id)
      private_owned_vmt = build(:managed_vmt,
                                appliance_type: private_owned_at)

      expect(subject.can?(:read, private_owned_vmt)).to be_truthy
    end

    it 'cannot see VMT assigned to private not owned AT' do
      priv_not_owned_at  = build(:appliance_type, visible_to: :author)
      priv_not_owned_vmt = build(:managed_vmt, appliance_type: priv_not_owned_at)

      expect(subject.can?(:read, priv_not_owned_vmt)).to be_falsy
    end

    it 'cannot see VMT not assigned to any AT' do
      not_assigned_vmt = build(:managed_vmt, appliance_type: nil)

      expect(subject.can?(:read, not_assigned_vmt)).to be_falsy
    end

    it 'cannot see not managed by atmosphere VMT' do
      not_managed_vmt = build(:virtual_machine_template,
                              managed_by_atmosphere: false)

      expect(subject.can?(:read, not_managed_vmt)).to be_falsy
    end

    it 'cannot see VMT assigned to development AT' do
      development_at = build(:appliance_type, visible_to: :developer)
      development_vmt = build(:managed_vmt, appliance_type: development_at)

      expect(subject.can?(:read, development_vmt)).to be_falsy
    end
  end

  context 'developer' do
    let(:user) { build(:developer, id: 1) }

    it 'can see VMT assigned to development AT' do
      development_at = build(:appliance_type, visible_to: 'developer')
      development_vmt = build(:managed_vmt, appliance_type: development_at)

      expect(subject.can?(:read, development_vmt)).to be_truthy
    end
  end

  context 'admin' do
    let(:user) { build(:admin) }

    it 'admin can do anything with VMT' do
      vmt = build(:virtual_machine_template)

      expect(subject.can?(:manage, vmt)).to be_truthy
    end
  end
end