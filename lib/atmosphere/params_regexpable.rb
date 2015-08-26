module Atmosphere
  module ParamsRegexpable
    def self.filter(payload, params)
      (payload || '').gsub(Atmosphere.config_param.regexp) do |param_name|
        params[param_name[Atmosphere.config_param.range]]
      end
    end

    def self.parameters(payload)
      if payload.blank?
        []
      else
        payload.scan(Atmosphere.config_param.regexp).
          map { |raw_param| raw_param[Atmosphere.config_param.range] }
      end
    end
  end
end
