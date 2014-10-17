require 'atmosphere'

module Air
  Revision = `git log --pretty=format:'%h' -n 1`

  def self.config
    Settings
  end
end