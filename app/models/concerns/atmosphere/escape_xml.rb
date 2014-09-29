# Simple utility for metadata XML creation

module EscapeXml
  extend ActiveSupport::Concern

  private

  def esc_xml(input)
    tab = {'&' => '&amp;', '<' => '&lt;', '>' => '&gt;', "'" => '&apos;', '"' => '&quot;'}
    input.nil? ? input : input.gsub(/[&<>'"]/) {|match| tab[match]}
  end

end
