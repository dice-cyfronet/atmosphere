module Slugable
  extend ActiveSupport::Concern

  def to_slug(str)
    value = str.mb_chars.normalize(:kd).gsub(/[^\x00-\x7F]/n, '').to_s
    value.gsub!(/[']+/, '')
    value.gsub!(/\W+/, ' ')
    value.strip!
    value.gsub!(' ', '-')
    value.gsub!('_', '-')
    value
  end
end
