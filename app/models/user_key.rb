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

  FINGER_PRINT_RE = /([\d\h]{2}:)+[\d\h]{2}/

  validates_presence_of :name, :public_key, :fingerprint
  attr_readonly :name, :public_key, :fingerprint
  before_create :generate_fingerprint
  belongs_to :user

  private
  def generate_fingerprint
    logger.info "Generating fingerprint for #{public_key}"
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
    self.fingerprint = fprint
  end
end
