module ParamsRegexpable
  def self.param_range
    @@param_range ||= eval(Air.config.config_param.range)
  end

  def self.param_regexp
    Air.config.config_param.regexp
  end

  def self.filter(payload, params)
    payload.gsub(/#{ParamsRegexpable.param_regexp}/) do |param_name|
      params[param_name[ParamsRegexpable.param_range]]
    end
  end

  def self.parameters(payload)
    payload.blank? ? [] : payload.scan(/#{ParamsRegexpable.param_regexp}/).collect { |raw_param| raw_param[ParamsRegexpable.param_range] }
  end
end