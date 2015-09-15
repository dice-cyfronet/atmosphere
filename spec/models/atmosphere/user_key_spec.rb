# == Schema Information
#
# Table name: user_keys
#
#  id          :integer          not null, primary key
#  name        :string(255)      not null
#  fingerprint :string(255)      not null
#  public_key  :text             not null
#  user_id     :integer          not null
#  created_at  :datetime
#  updated_at  :datetime
#

require 'rails_helper'

describe Atmosphere::UserKey do

  let (:t) {create(:tenant, technology: 'aws', config: '{"provider": "aws", "aws_access_key_id": "bzdura",  "aws_secret_access_key": "bzdura",  "region": "eu-west-1"}')}
  before do
    Fog.mock!
    t.cloud_client.reset_data
  end

  subject { create(:user_key) }
  it { should be_valid }
  [:name, :public_key, :user].each do |attr|
    it { should validate_presence_of attr}
  end
  it { should validate_uniqueness_of(:name).scoped_to(:user_id) }
  it 'should calculate fingerprint' do
    expect(subject.fingerprint).to eql '43:c5:5b:5f:b1:f1:50:43:ad:20:a6:92:6a:1f:9a:3a'
  end
  it { should belong_to :user }

  it 'should import key to tenant' do
    subject.name
    Atmosphere::Tenant.all.each { |t| subject.import_to_cloud(t) }
    Atmosphere::Tenant.all.each do |t|
      keypair = t.cloud_client.key_pairs.select{|k| k.name == subject.id_at_site}.first
      expect(keypair.name).to eq(subject.id_at_site)
    end
  end

  it 'should not raise error if key is imported twice' do
    subject.name
    Atmosphere::Tenant.all.each { |t| subject.import_to_cloud(t); subject.import_to_cloud(t) }
  end

  # there is no need for equivalent test for amazon because AWS does not raise error when trying to deleting key that was not imported
  it 'should handle key not found error when deleting key from openstack tenant' do
    t = create(:openstack_tenant)
    allow(t.cloud_client).to receive(:delete_key_pair).and_raise(Fog::Compute::OpenStack::NotFound.new)
    subject.destroy
  end

  it 'saving user key with invalid public key should fail' do
    user_key = build(:user_key, public_key: 'so invalid public key!!')
    saved = user_key.save
    expect(saved).to be_falsy
    errors = user_key.errors.messages
    expect(errors).to eql({public_key: ["bad type of key (only ssh-rsa is allowed)", "is invalid"]})
  end

  describe '#describe' do
    subject { create(:user_key) }

    context 'when key is used in running VM' do
      before do
        appl = create(:appliance)
        subject.appliances = [ appl ]
        subject.save
      end

      it 'throws error' do
        expect(subject.destroy).to be_falsy
      end
    end

    context 'when key is not assigned to any VM' do
      it 'it removed' do
        expect(subject.destroy).to be_truthy
      end
    end
  end

  describe '#id_at_site' do
    it 'normalizes key name' do
      user = build(:user, login: 'john')
      key = build(:user_key, user: user)
      expect(key.id_at_site).to start_with('john-')
    end
  end

  describe 'key validation' do

    let(:rsa_public_key_1) do
      'ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEAklOUpkDHrfHY17SbrmTIpNLTGK9Tjom/BWD'\
      'SUGPl+nafzlHDTYW7hdI4yZ5ew18JH4JW9jbhUFrviQzM7xlELEVf4h9lFX5QVkbPppSwg0'\
      'cda3Pbv7kOdJ/MTyBlWXFCR+HAo3FXRitBqxiX1nKhXpHAZsMciLq8V6RjsNAQwdsdMFvSl'\
      'VK/7XAt3FaoJoAsncM1Q9x5+3V0Ww68/eIFmb1zuUFljQJKprrX88XypNDvjYNby6vw/Pb0'\
      'rwert/EnmZ+AW4OZPnTPI89ZPmVMLuayrD2cE86Z/il8b+gw3r3+1nKatmIkjn2so1d01Qr'\
      'aTlMqVSsbxNrRFi9wrf+M7Q== factorized@sting'
    end
    let(:rsa_public_key_2) do
      'ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDBvn4PHPQMTo5gdcONyhoo2IpNn7uEBpW'\
      'sAL1biKWlv6fuiBJ9p21LGLBaHvvgk/odZ5t0pDo60cOKlrEdHWa5aOUSDbVgcdjvCyKUUW'\
      '1D1GC3QuSElHfyjk2pTWPOsJNL69yf2slsnVSVbJLvtCPTODSGWYyOtKchfBI0YC7TNOinz'\
      'kxxCbgwJHHlr2lLTZ+XmtS7iIm/6i05qxtmh6k59WOHO694FSov3xqLFuBoBvOC9sl24Cs1'\
      'bOCSmyZoVBv5uKMI1VmT3kYX58pW7u96pdbkWsEz3FwReCDUxDTbw0Nlv1O8CBcDQNrS0XF'\
      'lVGhzzTkh3HMyRnQijDvqWc2f factorized@sting'
    end

    it 'should pass on valid ssh-rsa key' do
      create(:user_key, public_key: rsa_public_key_1)
    end

    it 'should fail on ssh-dsa key' do
      expect { create(:user_key, public_key: 'ssh-dsa AAAAB3NzaC1yc2EAAAABIwAAAQEAklOUpkDHrfHY17SbrmTIpNLTGK9Tjom/BWDSUGPl+nafzlHDTYW7hdI4yZ5ew18JH4JW9jbhUFrviQzM7xlELEVf4h9lFX5QVkbPppSwg0cda3Pbv7kOdJ/MTyBlWXFCR+HAo3FXRitBqxiX1nKhXpHAZsMciLq8V6RjsNAQwdsdMFvSlVK/7XAt3FaoJoAsncM1Q9x5+3V0Ww68/eIFmb1zuUFljQJKprrX88XypNDvjYNby6vw/Pb0rwert/EnmZ+AW4OZPnTPI89ZPmVMLuayrD2cE86Z/il8b+gw3r3+1nKatmIkjn2so1d01QraTlMqVSsbxNrRFi9wrf+M7Q== factorized@sting') }
        .to raise_error
    end

    context 'sanitize public key payload' do
      it 'extracts first ssh-rsa entry' do
        key = create(
          :user_key,
          public_key: "#{rsa_public_key_1}\n#{rsa_public_key_2}"
        )
        key.reload
        expect(key.public_key).to eq rsa_public_key_1
      end
      it 'removes non-ssh-rsa content' do
        key = create(
          :user_key,
          public_key: "content that should be ignore#{rsa_public_key_1}\n"\
                      'more content to be igonred'
        )
        expect(key.public_key).to eq rsa_public_key_1
      end
      it 'is invalid if no ssh-rsa entry is present' do
        key = nil
        expect do
          key = create(
            :user_key,
            public_key: "content that should be ignore\n"\
                        'more content to be igonred'
          )
        end.to raise_error(ActiveRecord::RecordInvalid)
      end
    end
  end
end
