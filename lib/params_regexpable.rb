module ParamsRegexpable
  def self.param_range
    @@param_range ||= eval(Air.config.config_param.range)
  end

  def self.param_regexp
    Air.config.config_param.regexp
  end
end