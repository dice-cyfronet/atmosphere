module Filterable
  extend ActiveSupport::Concern

  private

  def filter
    model_class.new.attributes.keys.inject({}) do |filter, attr|
      key = attr.to_sym
      filter[key] = params[key].to_s.split(',') if params[key]
      filter
    end
  end

  def model_class
    controller_name.classify.constantize
  end
end