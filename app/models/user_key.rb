require 'tempfile'

# == Schema Information
#
# Table name: user_keys
#
#  id          :integer          not null, primary key
#  name        :string(255)
#  fingerprint :string(255)
#  public_key  :text
#  user_id     :integer          not null
#  created_at  :datetime
#  updated_at  :datetime
#

class UserKey < ActiveRecord::Base
  include Cloud

  FINGER_PRINT_RE = /([\d\h]{2}:)+[\d\h]{2}/

  validates_presence_of :name, :public_key, :user
  validates_uniqueness_of :name, :scope => :user_id
  attr_readonly :name, :public_key, :fingerprint
  before_create :generate_fingerprint, :import_to_clouds
  before_destroy :delete_in_clouds
  belongs_to :user

  #def name=(name)
    #raise 'Attribute :name has already been set and cannot be modified' unless name.blank?
    #logger.info 'Setting name'
    #write_attribute(:name, name)
  #end


  private
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
    ComputeSite.all.each do |cs|
      cloud_client = UserKey.get_cloud_client_for_site(cs.site_id)
      logger.debug "Importing key #{name} to #{cs.name}"
      cloud_client.import_key_pair(name, public_key)
      logger.info "Imported key #{name} to #{cs.name}"
    end
  end

  def delete_in_clouds
    ComputeSite.all.each do |cs|
      cloud_client = UserKey.get_cloud_client_for_site(cs.site_id)
      logger.debug "Deleting key #{name} from #{cs.name}"
      cloud_client.delete_key_pair(name)
      logger.info "Deleted key #{name} from #{cs.name}"
    end
  end
end
