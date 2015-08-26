module Atmosphere
  module Utils
    def min_elements_by(arr)
      min_elements = [arr.shift]
      arr.each do |e|
        if block_given?
          if yield(min_elements.first) > yield(e)
            min_elements = [e]
          elsif yield(min_elements.first) == yield(e)
            min_elements << e
          end
        else
          if min_elements.first > e
            min_elements = [e]
          elsif min_elements.first == e
            min_elements << e
          end
        end
      end
      min_elements.compact
    end

    def max_elements_by(arr)
      max_elements = [arr.shift]
      arr.each do |e|
        if block_given?
          if yield(max_elements.first) < yield(e)
            max_elements = [e]
          elsif yield(max_elements.first) == yield(e)
            max_elements << e
          end
        else
          if max_elements.first < e
            max_elements = [e]
          elsif max_elements.first == e
            max_elements << e
          end
        end
      end
      max_elements.compact
    end
  end
end
