class MetricValueType
  #0 - numeric float;
  #1 - character;
  #2 - log;
  #3 - numeric unsigned;
  #4 - text.

  def initialize(type)
    @type = type
  end

  def evaluate(value)
    if @type == "0"
      value.to_f
    elsif @type == "1"
      value
    elsif @type == "2"
      value
    elsif @type == "3"
      value.to_i
    elsif @type == "4"
      value
    end
  end

end