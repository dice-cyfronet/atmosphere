class MetricValueEvaluator

  #0 - numeric float;
  #1 - character;
  #2 - log;
  #3 - numeric unsigned;
  #4 - text.

  def self.evaluate(type, value)
    case type
      when 0
        value.to_f
      when 3
        value.to_i
      when 1, 2, 4
        value
      else
        value
    end
  end

end