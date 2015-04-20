require 'rails_helper'

describe Atmosphere::UserSerializer do
  context 'user details' do
    let(:current_user) { create(:user, roles: [:developer]) }

    it 'are visible for current user' do
      result = serialized_for(current_user)

      expect(result['user']['email']).to eq current_user.email
      expect(result['user']['roles']).to eq current_user.roles.map(&:to_s)
    end

    it 'are not visible for other user' do
      other_user = build(:user)

      result = serialized_for(other_user)

      expect(result['user']['email']).to be_nil
      expect(result['user']['roles']).to be_nil
    end

    it 'are visible for admin' do
      admin = build(:admin)
      other_user = build(:user)

      result = serialized_for(other_user, admin)

      expect(result['user']['email']).to eq other_user.email
      expect(result['user']['roles']).to eq other_user.roles.map(&:to_s)
    end
  end

  def serialized_for(user, current = current_user)
    serializer = Atmosphere::UserSerializer.new(user, scope: current)
    JSON.parse(serializer.to_json)
  end
end
