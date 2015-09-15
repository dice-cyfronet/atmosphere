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

require 'tempfile'

module Atmosphere
  class UserKey < ActiveRecord::Base
    FINGER_PRINT_RE = /([\d\h]{2}:)+[\d\h]{2}/
    RSA_PUBLIC_KEY_RE = /ssh-rsa .+$/
    SANITIZED_KEY_VALUE = 'SANITIZED! Provided key was not ssh-rsa type!'

    has_many :appliances,
             class_name: 'Atmosphere::Appliance'

    belongs_to :user,
               class_name: 'Atmosphere::User'

    validates :name,
              presence: true,
              uniqueness: { scope: :user_id }

    validates :public_key,
              presence: true

    validates :user,
              presence: true

    validate :check_key_type, :generate_fingerprint, unless: :persisted?

    attr_readonly :name, :public_key, :fingerprint

    before_validation :sanitize_public_key, if: :public_key?

    before_destroy :disallow_if_used_in_running_vm
    before_destroy :delete_in_clouds

    def id_at_site
      "#{user.login}-#{Digest::SHA1.hexdigest(fingerprint)}"
    end

    def sanitize_public_key
      self[:public_key] =
        public_key.try(:match, RSA_PUBLIC_KEY_RE).try(:[], 0) ||
        SANITIZED_KEY_VALUE
    end

    def generate_fingerprint
      logger.info "Generating fingerprint for #{public_key}"
      return unless public_key
      fprint = nil
      Tempfile.open('ssh_public_key', '/tmp') do |file|
        file.puts(public_key)
        file.rewind
        output = nil
        IO.popen(['ssh-keygen', '-lf', file.path]) do |out|
          output = out.read
          logger.info "Output #{output}"
        end
        if output.include? 'is not a public key file'
          logger.error "Provided public key #{public_key} is invalid"
          errors.add(:public_key, 'is invalid')
        elsif output
          logger.info output
          fprint = output.gsub(FINGER_PRINT_RE).first
          logger.info "Fingerprint #{fprint}"
          write_attribute(:fingerprint, fprint)
        end
      end
    end

    def check_key_type
      if !public_key.nil? && !public_key.starts_with?('ssh-rsa')
        logger.error "invalid type of provided public key #{public_key}"
        errors.add(:public_key, 'bad type of key (only ssh-rsa is allowed)')
      end
    end

    def import_to_clouds
      Tenant.all.each { |cs| import_to_cloud(cs) }
    end

    def import_to_cloud(t)
      cloud_client = t.cloud_client
      logger.debug "Importing key #{id_at_site} to #{t.name}"
      begin
        cloud_client.import_key_pair(id_at_site, public_key)
      rescue Excon::Errors::Conflict, Fog::Compute::AWS::Error
        logger.info $!
      end
      logger.info "Imported key #{id_at_site} to #{t.name}"
    end

    def delete_in_clouds
      Tenant.active.each do |t|
        cloud_client = t.cloud_client
        logger.debug "Deleting key #{id_at_site} from #{t.name}"
        # ignore key not found errors because it is possible that key was
        # never imported to tenant
        begin
          cloud_client.delete_key_pair(id_at_site)
        rescue Fog::Compute::OpenStack::NotFound,
               Fog::Compute::RackspaceV2::NotFound
        end
        logger.info "Deleted key #{id_at_site} from #{t.name}"
      end
    end

    def disallow_if_used_in_running_vm
      if appliances.count > 0
        errors.add(:base, 'Unable to remove key used in running application')
        return false
      end
    end
  end
end
