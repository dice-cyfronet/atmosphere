module ParamsRegexpable
  extend ActiveSupport::Concern

  private

  def param_range
    @param_range ||= eval(Air.config.config_param.range)
  end

  def param_regexp
    Air.config.config_param.regexp
  end
end