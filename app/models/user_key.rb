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
class UserKey < ActiveRecord::Base

  FINGER_PRINT_RE = /([\d\h]{2}:)+[\d\h]{2}/

  validates_presence_of :name, :public_key, :user
  validates_uniqueness_of :name, :scope => :user_id
  attr_readonly :name, :public_key, :fingerprint
  before_create :generate_fingerprint#, :import_to_clouds
  before_destroy :delete_in_clouds
  
  has_many :appliances
  belongs_to :user

  #def name=(name)
    #raise 'Attribute :name has already been set and cannot be modified' unless name.blank?
    #logger.info 'Setting name'
    #write_attribute(:name, name)
  #end

  def id_at_site
    "#{user.login}-#{name}"
  end

  def generate_fingerprint
    logger.info "Generating fingerprint for #{public_key}"
    return unless self.public_key    
    fprint = nil
    Tempfile.open('ssh_public_key', '/tmp') do |file|
      file.puts self.public_key
      file.rewind
      output = nil
      IO.popen("ssh-keygen -lf #{file.path}") {|out|
        output = out.read
      }
      if output
        logger.info output
        fprint = output.gsub(FINGER_PRINT_RE).first
      end
    end
    logger.info "Fingerprint #{fprint}"
    write_attribute(:fingerprint, fprint)
  end

  def import_to_clouds
    ComputeSite.all.each {|cs| import_to_cloud(cs)}
  end

  def import_to_cloud(cs)
    cloud_client = cs.cloud_client
    logger.debug "Importing key #{id_at_site} to #{cs.name}"
    begin
      cloud_client.import_key_pair(id_at_site, public_key)
    rescue Excon::Errors::Conflict, Fog::Compute::AWS::Error
      logger.info $!
    end
    logger.info "Imported key #{id_at_site} to #{cs.name}"
  end

  def delete_in_clouds
    ComputeSite.all.each do |cs|
      cloud_client = cs.cloud_client
      logger.debug "Deleting key #{id_at_site} from #{cs.name}"
      cloud_client.delete_key_pair(id_at_site)
      logger.info "Deleted key #{id_at_site} from #{cs.name}"
    end
  end
end
